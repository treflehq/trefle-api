require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#terms_up_to_date?' do
    it 'is false when terms were never accepted' do
      user = build(:user, accepts_terms: false)
      expect(user.terms_up_to_date?).to be false
    end

    it 'is false when the accepted version is stale' do
      user = build(:user, accepts_terms: false, terms_accepted_at: 1.year.ago, terms_version: 'old-version')
      expect(user.terms_up_to_date?).to be false
    end

    it 'is true once the current version has been recorded' do
      user = create(:user, accepts_terms: true)
      expect(user.terms_up_to_date?).to be true
    end
  end

  describe 'terms acceptance recording' do
    it 'stamps terms_accepted_at/terms_version when accepts_terms is truthy on save' do
      user = build(:user, accepts_terms: true, terms_accepted_at: nil, terms_version: nil)

      user.save!

      expect(user.terms_accepted_at).to be_present
      expect(user.terms_version).to eq(TERMS_VERSION)
    end

    it 'does not touch terms fields when accepts_terms is falsy' do
      user = build(:user, accepts_terms: false, terms_accepted_at: nil, terms_version: nil)

      user.save!

      expect(user.terms_accepted_at).to be_nil
      expect(user.terms_version).to be_nil
    end
  end

  describe 'accepts_terms acceptance validation' do
    it 'does not block a plain save -- only forms that opt in via enforce_terms_acceptance do' do
      user = build(:user, accepts_terms: false)
      expect(user).to be_valid
    end

    it 'blocks save when enforce_terms_acceptance is set and the box was not checked' do
      user = build(:user, accepts_terms: false)
      user.enforce_terms_acceptance = true

      expect(user).not_to be_valid
      expect(user.errors[:accepts_terms]).to be_present
    end

    it 'passes when enforce_terms_acceptance is set and the box was checked' do
      user = build(:user, accepts_terms: true)
      user.enforce_terms_acceptance = true

      expect(user).to be_valid
    end
  end
end
