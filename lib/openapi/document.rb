module Openapi
  # The OpenAPI 3.0 description of the public API, as served by
  # GET /api/v1/openapi.json and .yaml (Api::V1::OpenapiController).
  #
  # The document is not written by hand: `rake rswag:specs:swaggerize`
  # generates it from the rswag request specs (spec/requests/api/v1, with the
  # response schemas of lib/schemas and the parameters of
  # lib/schemas/v1/parameters.rb) into PATH, which is committed. CI regenerates
  # it and fails when the committed file is behind, so what this class serves
  # is always the description of the code it ships with. Read once per process.
  class Document
    PATH = Rails.root.join('public/swagger/v1/swagger.yaml')

    class << self
      def to_h
        @to_h ||= YAML.safe_load_file(PATH)
      end

      def to_json(*)
        @to_json ||= JSON.pretty_generate(to_h)
      end

      def to_yaml
        @to_yaml ||= File.read(PATH)
      end

      def etag
        @etag ||= Digest::SHA256.hexdigest(to_yaml)
      end

      def version
        to_h.dig('info', 'version')
      end
    end
  end
end
