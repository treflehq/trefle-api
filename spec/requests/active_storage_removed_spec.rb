require 'rails_helper'

RSpec.describe 'ActiveStorage removal', type: :request do
  # Sentry API-8D: the direct-upload endpoint 500ed because the engine was
  # required (mounting its routes) but its tables were never migrated, and
  # nothing in the app uses attachments. ActiveStorage is removed rather than
  # completed (see #53 for the actual photo-upload feature, unstarted); the
  # route must simply be gone now.
  describe 'POST /rails/active_storage/direct_uploads' do
    it 'no longer mounts the route' do
      post '/rails/active_storage/direct_uploads', params: { blob: { filename: 'x.png' } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
