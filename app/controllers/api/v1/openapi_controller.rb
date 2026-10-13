# GET /api/v1/openapi.json and /api/v1/openapi.yaml: the OpenAPI 3.0 document
# describing this API (Openapi::Document). It is what a client reads before it
# has a token, and what docs.trefle.io/reference renders, so it deliberately
# does not inherit Api::ApiController and its authorize_request!. Cross-origin
# reads are already allowed on /api/* by config/initializers/cors.rb.
class Api::V1::OpenapiController < ActionController::API
  include ActionController::MimeResponds

  def show
    expires_in 1.hour, public: true
    return unless stale?(etag: Openapi::Document.etag, public: true)

    respond_to do |format|
      format.json { render json: Openapi::Document.to_json }
      format.yaml { render plain: Openapi::Document.to_yaml, content_type: 'application/yaml' }
    end
  end
end
