require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#app_revision' do
    it 'returns the APP_REVISION env var when set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('v2.0.2')

      expect(helper.app_revision).to eq('v2.0.2')
    end

    it 'falls back to "dev" when unset' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return(nil)

      expect(helper.app_revision).to eq('dev')
    end

    it 'falls back to "dev" when blank' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('')

      expect(helper.app_revision).to eq('dev')
    end
  end

  describe '#app_revision_url' do
    it 'links to the GitHub release for a v* tag' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('v2.0.2')

      expect(helper.app_revision_url).to eq('https://github.com/treflehq/trefle-api/releases/tag/v2.0.2')
    end

    it 'is nil for the "dev" fallback' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return(nil)

      expect(helper.app_revision_url).to be_nil
    end

    it 'is nil for a non v* revision' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('APP_REVISION').and_return('local-build')

      expect(helper.app_revision_url).to be_nil
    end
  end
end
