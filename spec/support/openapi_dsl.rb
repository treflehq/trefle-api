require 'rspec/expectations'

# Extends the rswag example groups (spec/swagger_helper.rb) with the pieces
# every documented endpoint shares, so each spec declares them in one line and
# the published document stays uniform.
module OpenapiDsl
  RATE_LIMIT = 60 # the default per-minute limit of config/initializers/rack_attack.rb

  # The reusable query parameters of lib/schemas/v1/parameters.rb, by name.
  # rswag resolves the `$ref` when it builds the request, so a `let` of the
  # same name (`let(:filter) { { edible: 'true' } }`) is sent, deepObject-style.
  def parameters(*names)
    names.each {|name| parameter '$ref' => "#/components/parameters/#{name}" }
  end

  # Every /api endpoint is throttled by rack-attack: documents the 429 and
  # exercises it. Sixty real requests per operation would make the suite crawl,
  # so the counter of this client is filled through rack-attack's own cache
  # first and the documented request is the one that tips it over. The block
  # holds the `let`s the operation needs (path parameters, `q`).
  def response_too_many_requests(&lets)
    response '429', 'Too many requests: the rate limit is exceeded' do
      schema Schemas::Helpers.error_schema
      header 'RateLimit-Limit', schema: { type: :integer }, description: 'Requests allowed per minute'
      header 'RateLimit-Remaining', schema: { type: :integer }, description: 'Requests left in the current minute'
      header 'RateLimit-Reset', schema: { type: :integer }, description: 'Unix timestamp at which the counter resets'
      header 'Retry-After', schema: { type: :integer }, description: 'Seconds to wait before retrying'

      let(:token) { user.token }
      class_exec(&lets) if lets

      # Anonymous endpoints are counted by IP alone (Rack::Attack.token is nil)
      anonymous = metadata[:operation][:security] == []

      # Frozen so the fill and the request land in the same one-minute window.
      around {|example| freeze_time { example.run } }
      before do
        client = anonymous ? '' : token.downcase
        OpenapiDsl::RATE_LIMIT.times { Rack::Attack.cache.count("#{Rack::Attack::REQUEST_PER_IP_THROTTLE}:127.0.0.1-#{client}", 60) }
      end
      after { Rack::Attack.cache.reset! }

      run_test!
    end
  end
end
