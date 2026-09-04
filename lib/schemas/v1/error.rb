module Schemas
  module V1
    module Error
      # The single envelope every /api error response shares (issue #216),
      # loosely inspired by RFC 9457 without adopting its media type.
      # `messages` duplicates `message` for one deprecation cycle -- existing
      # clients (mobile/third-party) read that key today.
      def self.schema
        Helpers.object_of({
          error: { type: :boolean, example: true },
          code: { type: :string, description: 'A machine-readable error code, stable across releases', example: 'not_found' },
          message: { type: :string, description: 'A human-readable description of the error' },
          messages: { type: :string, description: 'Deprecated alias of `message`, kept for backward compatibility' },
          details: { type: :object, nullable: true, description: 'Optional structured context about the error' }
        }, extras: { required: %w[error code message] })
      end
    end
  end
end
