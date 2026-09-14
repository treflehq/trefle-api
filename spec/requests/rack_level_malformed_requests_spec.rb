require 'rails_helper'

# Three Rack-level 500s a client can trigger with nothing but a header or a
# malformed body -- none of them reach a controller (#331). Fixed by
# RateLimitHeadersMiddleware (config/initializers/rack_attack.rb), which is
# `unshift`ed to the very top of the middleware stack so it can catch all
# three regardless of where in the stack each one is raised or rescued.
RSpec.describe 'Rack-level malformed requests', type: :request do
  before { Rack::Attack.cache.reset! }
  after { Rack::Attack.cache.reset! }

  describe 'conflicting Client-IP / X-Forwarded-For headers' do
    # ActionDispatch::RemoteIp::IpSpoofAttackError -- API-82. Raised from
    # Rails::Rack::Logger while logging the request line, before routing;
    # any path is affected.
    it 'returns 400 instead of a raised IpSpoofAttackError' do
      get '/api/v1/', headers: { 'Client-IP' => '127.0.0.1', 'X-Forwarded-For' => '10.42.0.1' }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'a truncated/empty multipart body' do
    # Rack::Multipart::EmptyContentError -- API-89. A Content-Length that
    # matches an accurately-truncated body (an opening boundary line with
    # nothing after it) leaves Rack's multipart parser wanting more input
    # than was declared, which is what raises this -- an all-empty body
    # short-circuits before the parser ever runs (Rack::Multipart::Parser
    # .parse returns early for `content_length == 0`) and doesn't reproduce
    # it. Reached, pre-fix, via Rack::Attack's own safelist (evaluated on
    # every request regardless of path) calling `req.params` on a plain
    # Rack::Request, which -- unlike ActionDispatch::Request -- has no
    # rescue for this.
    it 'returns 400 instead of a raised EmptyContentError' do
      post '/users/sign_in', params: "--AaB03x\r\n", headers: { 'CONTENT_TYPE' => 'multipart/form-data; boundary=AaB03x' }

      expect(response).to have_http_status(:bad_request)
    end

    # By the time this reaches Rack, it's no longer Rack::Multipart::
    # EmptyContentError -- Rack::MethodOverride's own parse attempt
    # already swallowed that -- but ActionController::BadRequest, raised
    # from ActionDispatch::Request#POST re-parsing the same truncated
    # body for real. Left to the app that happens deep inside
    # ActionController::Instrumentation#process_action, too early for a
    # controller's own `rescue_from` and, in a "local" request (always
    # true in this env, see config.consider_all_requests_local), fully
    # handled by ActionDispatch::DebugExceptions before either mechanism
    # in RateLimitHeadersMiddleware gets a chance -- so this needs an
    # actual /api/* route, and an assertion on the response shape, not
    # just its status, to catch a regression back to that HTML page.
    it 'returns the documented /api error envelope for an /api route' do
      post '/api/auth/claim', params: "--AaB03x\r\n", headers: { 'CONTENT_TYPE' => 'multipart/form-data; boundary=AaB03x' }

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to eq('application/json')
      expect(response.parsed_body).to include(
        'error' => true,
        'code' => 'bad_request'
      )
    end
  end

  describe 'a non-UTF-8 form field name' do
    # Encoding::CompatibilityError -- API-8C. A multipart part is allowed
    # its own Content-Type with a charset (RFC 7578); Rack retags the
    # field *name* (not just the value) with that charset when the part
    # isn't a file upload (Rack::Multipart::Parser#tag_multipart_encoding).
    # A non-ASCII-compatible charset like UTF-16LE then blows up the first
    # time that name is compared against a plain UTF-8 string -- here, in
    # Rack::MethodOverride#method_override_param -> req.POST ->
    # Rack::QueryParser#_normalize_params's `name.index('[', 1)`, matching
    # the exact frame API-8C reported. MethodOverride runs before the rest
    # of the stack and only rescues a handful of other error classes.
    it 'returns 400 instead of a raised Encoding::CompatibilityError' do
      boundary = 'AaB03x'
      body = [
        "--#{boundary}",
        'Content-Disposition: form-data; name="foo"',
        'Content-Type: text/plain; charset=UTF-16LE',
        '',
        'bar',
        "--#{boundary}--",
        ''
      ].join("\r\n")

      post '/users/sign_in', params: body, headers: { 'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'rate limiting' do
    let(:user) { create(:user) }

    it 'buckets by the true client IP, not a client-supplied Client-IP header' do
      get '/api/v1/', params: { token: user.token }, headers: { 'Client-IP' => '1.2.3.4' }
      first_remaining = response.headers['RateLimit-Remaining'].to_i

      get '/api/v1/', params: { token: user.token }, headers: { 'Client-IP' => '9.9.9.9' }
      second_remaining = response.headers['RateLimit-Remaining'].to_i

      expect(second_remaining).to eq(first_remaining - 1)
    end
  end
end
