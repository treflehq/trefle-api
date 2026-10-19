require 'rails_helper'

RSpec.describe Migrators::StaleFactProjection do
  let(:species) { create(:species) }
  let(:jan_may) { Species.bloom_months.to_i(%i[jan may]) }
  let(:apr_may) { Species.bloom_months.to_i(%i[apr may]) }
  let(:jun_jul) { Species.bloom_months.to_i(%i[jun jul]) }

  def record(value, notes: 'TRY 7.0 datasets 4, 174')
    SpeciesFact.record!(species: species, attribute_name: 'bloom_months', source: 'try', value: value,
                        notes: notes, n_observations: 2)
  end

  def column
    species.reload.read_attribute(:bloom_months)
  end

  context 'when the column holds the mask of a superseded fact citing the dataset' do
    before do
      record('jan, may') # the misread, promoted into the column
      species.update_columns(bloom_months: jan_may)
      record('apr, may') # the re-import supersedes it
    end

    it 'empties the column so promotion can refill it' do
      result = described_class.run(dry_run: false)

      expect(column).to eq(0)
      expect(result.to_h).to include(candidates: 1, reset: 1, kept_current: 0)
    end

    it 'counts but changes nothing on a dry run' do
      result = described_class.run

      expect(column).to eq(jan_may)
      expect(result.reset).to eq(1)
    end

    it 'leaves the facts as they are: the superseded one is the trail' do
      described_class.run(dry_run: false)

      expect(species.species_facts.for_attribute('bloom_months').pluck(:value, :status))
        .to contain_exactly(['jan, may', 'superseded'], ['apr, may', 'active'])
    end

    it 'is replayable' do
      described_class.run(dry_run: false)
      result = described_class.run(dry_run: false)

      expect(result.to_h).to include(reset: 0, already_empty: 1)
    end
  end

  it 'keeps a column equal to the active fact' do
    record('jan, may')
    record('apr, may')
    species.update_columns(bloom_months: apr_may)

    result = described_class.run(dry_run: false)

    expect(column).to eq(apr_may)
    expect(result.to_h).to include(reset: 0, kept_current: 1)
  end

  it 'leaves a column that matches no fact of the source' do
    record('jan, may')
    record('apr, may')
    species.update_columns(bloom_months: jun_jul)

    result = described_class.run(dry_run: false)

    expect(column).to eq(jun_jul)
    expect(result.to_h).to include(reset: 0, not_from_source: 1)
  end

  it 'empties a column whose only backing is now a rejected fact' do
    fact = record('apr, dec')
    species.update_columns(bloom_months: Species.bloom_months.to_i(%i[apr dec]))
    fact.update!(status: :rejected, notes: "#{fact.notes}\ndataset 174 value 49 is not a month")

    result = described_class.run(dry_run: false)

    expect(column).to eq(0)
    expect(result.reset).to eq(1)
  end

  context 'when the superseded fact cites another dataset' do
    before do
      record('jan, may', notes: 'TRY 7.0 datasets 4, 17')
      species.update_columns(bloom_months: jan_may)
      record('apr, may', notes: 'TRY 7.0 datasets 4, 17')
    end

    it 'is not a candidate for dataset 174 (17 is not 174, nor is the 7 of the release)' do
      result = described_class.run(dry_run: false)

      expect(column).to eq(jan_may)
      expect(result.candidates).to eq(0)
    end

    it 'is reset when no dataset is named' do
      result = described_class.run(dataset: nil, dry_run: false)

      expect(column).to eq(0)
      expect(result.reset).to eq(1)
    end
  end

  it 'refuses an attribute that is not a flag column' do
    expect { described_class.run(attribute: 'maximum_height_cm') }.to raise_error(ArgumentError, /not a flag column/)
  end
end
