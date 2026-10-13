# frozen_string_literal: true

require 'rails_helper'
require File.expand_path('./support/openapi_dsl', __dir__)

# The OpenAPI document is generated from the request specs under
# spec/requests/api/v1 (`rake rswag:specs:swaggerize`, which re-runs them with
# --dry-run and collects the metadata), into public/swagger/v1/swagger.yaml.
# That file is committed, served by GET /api/v1/openapi.json|yaml and rendered
# on docs.trefle.io/reference; CI regenerates it and fails when it is behind.
#
# Paths are declared relative to the server below (`path '/species'` for
# https://trefle.io/api/v1/species): rswag prefixes the server path when it
# builds the test request. POST /api/auth/claim sits outside /api/v1 and
# carries its own `servers` (spec/requests/api/v1/900_auth_spec.rb).
RSpec.configure do |config|
  config.extend OpenapiDsl, type: :request
  config.include ActiveSupport::Testing::TimeHelpers, type: :request

  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('public/swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Trefle API v1',
        version: TrefleAdmin::Application::VERSION,
        description: <<~DESC,
          A REST API over a global plants database: taxonomy, botanical traits, distribution zones and images.

          Every endpoint but `GET /api/v1` and this document requires a token, passed either as `Authorization: Bearer <token>` or as a `token` query parameter. Get yours on https://trefle.io/profile; browser applications claim an origin-bound JWT with `POST /api/auth/claim` instead of shipping the account token.

          Collections take `page` and accept `filter[field]`, `filter_not[field]`, `order[field]` and `range[field]` query parameters: one key per field, the allowed keys are listed per endpoint and an unknown key answers 400. Every error answers the same envelope (`error`, `code`, `message`). Requests are rate limited (60 a minute by default) and every response carries `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`.

          This document is generated from the API test suite and served by the API itself at https://trefle.io/api/v1/openapi.json (or .yaml). A plain-text guide for programs lives at https://trefle.io/llms.txt.

          Trefle compiles data from external sources; each record lists the sources it was built from, with their own licence. Attribution is required — see https://trefle.io/citation.
        DESC
        license: {
          name: 'CC-BY-4.0',
          url: 'https://creativecommons.org/licenses/by/4.0/'
        }
      },
      externalDocs: {
        description: 'Guides: getting started, filtering, sorting, pagination, searching',
        url: 'https://docs.trefle.io'
      },
      paths: {},
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: 'The account access token, or the JWT claimed with `POST /api/auth/claim`, as `Authorization: Bearer <token>`'
          },
          token: {
            type: :apiKey,
            name: 'token',
            in: :query,
            description: 'The same token as a `token` query parameter, for clients that cannot set headers'
          }
        },
        parameters: Schemas::V1::PARAMETERS,
        schemas: Schemas::V1::SCHEMAS
      },
      servers: [
        {
          url: 'https://trefle.io/api/v1'
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
