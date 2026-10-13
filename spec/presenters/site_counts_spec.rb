require 'rails_helper'

# The suite seeds a taxonomy (spec/support/test_seeds.rb), so the counts
# below are checked as deltas, not absolute totals.
RSpec.describe SiteCounts do
  describe '.species_count' do
    it 'counts every row of the species table, whatever its rank' do
      baseline = described_class.species_count
      genus = create(:genus)
      create(:species, genus_id: genus.id, rank: 'species')
      create(:species, genus_id: genus.id, rank: 'var', scientific_name: "#{genus.name} alpha var. beta")

      expect(described_class.species_count).to eq(baseline + 2)
      expect(described_class.species_count).to eq(Species.count)
    end
  end

  describe '.plants_count' do
    it 'matches the plants table' do
      expect(described_class.plants_count).to eq(Plant.count)
    end
  end

  describe '.approximate' do
    it 'rounds large counts to the nearest thousand' do
      expect(described_class.approximate(499_374)).to eq(499_000)
      expect(described_class.approximate(453_551)).to eq(454_000)
      expect(described_class.approximate(10_500)).to eq(11_000)
    end

    it 'leaves small counts untouched' do
      expect(described_class.approximate(0)).to eq(0)
      expect(described_class.approximate(1_234)).to eq(1_234)
      expect(described_class.approximate(9_999)).to eq(9_999)
    end
  end

  describe 'caching' do
    around do |example|
      store = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = store
    end

    it 'serves both counts from the cache for a day' do
      expect(Rails.cache).to receive(:fetch)
        .with('site_counts/v1/species', expires_in: 1.day).and_call_original
      expect(Rails.cache).to receive(:fetch)
        .with('site_counts/v1/plants', expires_in: 1.day).and_call_original

      described_class.species_count
      described_class.plants_count
    end
  end
end
