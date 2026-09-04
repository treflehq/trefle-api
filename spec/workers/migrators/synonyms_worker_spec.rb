require 'rails_helper'
RSpec.describe Migrators::SynonymsWorker, type: :worker do
  it 'delegates to Migrators::Synonyms' do
    allow(Migrators::Synonyms).to receive(:run)

    described_class.new.perform

    expect(Migrators::Synonyms).to have_received(:run)
  end
end
