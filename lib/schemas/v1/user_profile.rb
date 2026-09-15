module Schemas
  module V1
    module UserProfile
      def self.schema
        Helpers.object_of(
          {
            name: { type: :string, nullable: true, description: 'Null when authenticating with a JWT rather than a personal token' },
            email: { type: :string, nullable: true, description: 'Null when authenticating with a JWT rather than a personal token' },
            image_url: { type: :string, nullable: true, description: 'The Gravatar URL for the account' },
            organization_name: { type: :string, nullable: true },
            organization_url: { type: :string, nullable: true },
            account_type: { type: :string, nullable: true },
            created_at: { type: :string, nullable: true, description: 'Null when authenticating with a JWT rather than a personal token' }
          }
        )
      end
    end
  end
end
