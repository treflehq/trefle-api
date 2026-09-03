require 'rails_helper'

RSpec.describe 'Management backoffice', type: :request do

  describe 'access control' do
    it 'refuses anonymous visitors' do
      get management_path
      expect(response).not_to have_http_status(:ok)
    end

    it 'refuses non-admin users' do
      login_as create(:user), scope: :user
      get management_path
      expect(response).not_to have_http_status(:ok)
    end

    %w[species plants users kingdoms subkingdoms divisions division_classes division_orders
       families genuses record_corrections user_queries species_images foreign_sources].each do |section|
      it "refuses non-admin users on /management/#{section}" do
        login_as create(:user), scope: :user
        get "/management/#{section}"
        expect(response).not_to have_http_status(:ok)
      end
    end
  end

  describe 'as an admin' do
    before { login_as create(:admin), scope: :user }

    %w[species plants users kingdoms subkingdoms divisions division_classes division_orders
       families genuses record_corrections user_queries species_images foreign_sources].each do |section|
      it "renders /management/#{section}" do
        get "/management/#{section}"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'renders the dashboard' do
      get management_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders a species page and updates it' do
      species = Species.friendly.find('abies-alba')
      get "/management/species/#{species.slug}"
      expect(response).to have_http_status(:ok)

      patch "/management/species/#{species.slug}", params: { species: { observations: 'Updated by spec' } }
      expect(response).to redirect_to("/management/species/#{species.slug}")
      expect(species.reload.observations).to eq('Updated by spec')
      expect(species.reviewed_at).to be_present
    end

    describe 'corrections review' do
      let!(:correction) do
        create(
          :record_correction,
          notes: 'Height is wrong',
          correction_json: { maximum_height_value: 4200, maximum_height_unit: 'cm' }.to_json
        )
      end

      it 'accepts a correction and applies it to the record' do
        patch "/management/record_corrections/#{correction.id}/accept"
        expect(response).to redirect_to(management_record_corrections_path)
        expect(correction.reload).to be_accepted_change_status
        expect(correction.record.reload.maximum_height_cm).to eq(4200)
      end

      it 'rejects a correction without touching the record' do
        before_height = correction.record.maximum_height_cm
        patch "/management/record_corrections/#{correction.id}/reject"
        expect(response).to redirect_to(management_record_corrections_path)
        expect(correction.reload).to be_rejected_change_status
        expect(correction.record.reload.maximum_height_cm).to eq(before_height)
      end
    end
  end
end
