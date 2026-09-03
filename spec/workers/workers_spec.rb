require 'rails_helper'

RSpec.describe 'Recurring workers' do
  let(:species) { Species.friendly.find('abies-alba') }

  describe RunCheckWorker do
    it 'runs the local checks for a species' do
      species.update_columns(genus_id: Genus.find_by!(name: 'Abelia').id, genus_name: 'Abelia')

      described_class.new.perform(species.id)

      expect(RecordCorrection.pluck(:warning_type, :notes)).to contain_exactly(
        ['Checks::GenusName', a_string_including('genus')]
      )
    end

    it 'leaves a clean species alone' do
      described_class.new.perform(species.id)

      expect(RecordCorrection.pluck(:warning_type, :notes)).to eq([])
    end

    it 'stamps checked_at so the sweep can rotate' do
      expect { described_class.new.perform(species.id) }
        .to change { species.reload.checked_at }.from(nil)
    end
  end

  describe ChecksSweepWorker do
    it 'enqueues the least recently checked species first' do
      Species.update_all(checked_at: 1.day.ago)
      species.update_columns(checked_at: nil)
      allow(RunCheckWorker).to receive(:perform_async)

      described_class.new.perform(1)

      expect(RunCheckWorker).to have_received(:perform_async).with(species.id)
    end
  end

  describe SpeciesRefreshWorker do
    it 'saves the species to refresh its computed fields' do
      species.update_columns(completion_ratio: 0, complete_data: false)

      described_class.new.perform(species.id)

      expect(species.reload.complete_data).to be(true)
    end
  end

  describe UserQueryWorker do
    before { UserQuery.clean_all! }

    it 'drops counters whose user has been deleted instead of crashing' do
      user = create(:user)
      UserQuery.mark!(user.id)
      user.destroy!

      expect { described_class.new.perform }.not_to change(UserQuery, :count)
    end

    it 'flushes the redis counters into user_queries rows' do
      user = create(:user)
      UserQuery.mark!(user.id)
      UserQuery.mark!(user.id)

      expect { described_class.new.perform }.to change(UserQuery, :count).by(1)
      expect(UserQuery.last.counter).to eq(2)
      expect(UserQuery.last.user_id).to eq(user.id)
    end

    it 'is idempotent once the counters are flushed' do
      user = create(:user)
      UserQuery.mark!(user.id)
      described_class.new.perform

      expect { described_class.new.perform }.not_to(change { UserQuery.sum(:counter) })
    end
  end

  describe Search::ReindexSpeciesWorker, search: true do
    it 'processes the searchkick queue without raising' do
      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
