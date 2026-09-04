require 'rails_helper'

RSpec.describe Migrators::CompletionWorker, type: :worker do
  it 'recomputes completion_ratio and complete_data for every species and plant' do
    species = Species.friendly.find('abies-alba')
    species.update_columns(completion_ratio: 0, complete_data: false)
    species.plant.update_columns(completion_ratio: 0, complete_data: false)

    described_class.new.perform

    expected = species.reload.current_completion_percentage
    expect(species.completion_ratio).to eq(expected)
    expect(species.complete_data).to eq(expected > 50)
    expect(species.plant.reload.completion_ratio).to eq(expected)
  end

  it 'returns true' do
    expect(described_class.new.perform).to be(true)
  end
end
