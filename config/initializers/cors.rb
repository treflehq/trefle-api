# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Client-side apps are expected to call the read endpoints directly from the
# browser (community report: #91) and to claim an origin-bound JWT via
# POST /api/auth/claim (see Api::Auth::AuthController#claim, and
# Api::ApiController#check_jwt! for the origin check enforced on that token
# afterwards -- CORS headers are a browser-side courtesy, not the security
# boundary). Everything else under /api (writes: corrections, reports...)
# is intentionally left alone here and keeps relying on the existing
# Api::ApiController#cors_preflight_check / #cors_set_access_control_headers.
#
# rack-cors's Resource#match? (used for BOTH preflight and actual requests)
# only consults matches_path? and if_proc -- the `methods:` list below is
# only enforced during preflight (Resource#process_preflight). Without the
# `if:` guard, an actual cross-origin write request (POST /report, etc.)
# would still get matched by this catch-all and stamped with CORS headers,
# regardless of its verb. The `if:` proc is what actually keeps writes out.
read_methods = %w[GET HEAD OPTIONS].freeze
rate_limit_headers = %w[RateLimit-Limit RateLimit-Remaining RateLimit-Reset].freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    # More specific than the /api/* resource below -- rack-cors matches the
    # first resource whose path fits, so this one has to come first or the
    # catch-all would shadow it and preflight POST requests would be denied.
    resource '/api/auth/claim',
             headers: :any,
             methods: %i[post options],
             expose: rate_limit_headers

    resource '/api/*',
             headers: :any,
             methods: %i[get head options],
             if: ->(env) { read_methods.include?(env['REQUEST_METHOD']) },
             expose: rate_limit_headers
  end
end
