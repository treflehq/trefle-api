require 'rails_helper'

# The three rules from lib/migrators/fact_promotion.rb, each pinned by the
# case that would break it. See trefle-api#328.
RSpec.describe Migrators::FactPromotion do
  let(:species) { create(:species) }

  def record(attr, value, source: 'try', observations: 5, status: :active)
    SpeciesFact.record!(species: species, attribute_name: attr, source: source,
                        value: value, n_observations: observations, status: status)
  end

  describe 'rule 1: an empty column only' do
    it 'fills a column that is empty' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid')

      expect { described_class.run(dry_run: false) }
        .to(change { species.reload.growth_rate }.from(nil).to('Rapid'))
    end

    it 'never overwrites a filled column, whatever the fact says' do
      species.update!(growth_rate: 'Slow')
      record('growth_rate', 'Rapid')

      expect { described_class.run(dry_run: false) }
        .not_to(change { species.reload.growth_rate })
    end

    it 'treats 0 on a zero_means_empty column as empty' do
      species.update!(flower_color: 0)
      record('flower_color', 'yellow')

      described_class.run(dry_run: false)

      expect(species.reload.flower_color.to_a).to eq(%i[yellow])
    end

    it 'treats false as a filled value, not an empty one' do
      species.update!(flower_conspicuous: false)
      record('flower_conspicuous', 'true')

      expect { described_class.run(dry_run: false) }
        .not_to(change { species.reload.flower_conspicuous })
    end
  end

  describe 'rule 2: only attributes in the traits.yml contract' do
    # The case with teeth: a real, empty Species column that traits.yml
    # deliberately leaves out (USDA legacy agronomic ratings, excluded from
    # the contract). Widening the allow-list to Species.column_names would
    # fill it -- which is what this pins against.
    it 'ignores a real column that the contract excludes' do
      expect(Species.column_names).to include('protein_potential')
      expect(Traits.completion_fields).not_to include('protein_potential')
      species.update!(protein_potential: nil)
      record('protein_potential', 'High')

      expect { described_class.run(dry_run: false) }
        .not_to(change { species.reload.protein_potential })
    end

    it 'ignores a fact-only attribute that is no column at all' do
      record('human_usage_type', 'food')

      expect(described_class.run(dry_run: false).promoted).to eq(0)
    end

    it 'ignores the Ellenberg indicators marked promoted: false' do
      record('soil_ph_indicator', '5')
      record('temperature_indicator', '6')

      expect(described_class.run(dry_run: false).promoted).to eq(0)
    end
  end

  describe 'rule 3: only corroborated facts' do
    it 'skips a fact resting on a single measurement' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid', observations: 1)

      expect { described_class.run(dry_run: false) }
        .not_to(change { species.reload.growth_rate })
    end

    it 'promotes a fact that carries no observation count' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid', observations: nil)

      expect { described_class.run(dry_run: false) }
        .to(change { species.reload.growth_rate }.to('Rapid'))
    end
  end

  describe 'source arbitration' do
    it 'takes the stronger source when two claim the same empty column' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Slow', source: 'powo')
      record('growth_rate', 'Rapid', source: 'try') # try outranks powo in traits.yml

      described_class.run(dry_run: false)

      expect(species.reload.growth_rate).to eq('Rapid')
    end

    it 'can be restricted to one source' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Slow', source: 'powo')

      described_class.run(source: 'try', dry_run: false)

      expect(species.reload.growth_rate).to be_nil
    end
  end

  describe 'superseded and rejected facts' do
    it 'ignores a fact that is not active' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid', status: :rejected)

      expect { described_class.run(dry_run: false) }
        .not_to(change { species.reload.growth_rate })
    end
  end

  describe 'dry run' do
    it 'reports what it would do and writes nothing' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid')

      result = described_class.run(dry_run: true)

      expect(result.promoted).to eq(1)
      expect(result.per_attribute['growth_rate']).to eq(1)
      expect(species.reload.growth_rate).to be_nil
    end
  end

  describe 'replayability' do
    it 'is a no-op on the second run, because the column is no longer empty' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid')

      expect(described_class.run(dry_run: false).promoted).to eq(1)
      expect(described_class.run(dry_run: false).promoted).to eq(0)
    end
  end

  describe 'the completion ratio' do
    it 'recomputes when a column fills, through the before_save hook' do
      species.update!(growth_rate: nil)
      record('growth_rate', 'Rapid')

      expect { described_class.run(dry_run: false) }
        .to(change { species.reload.completion_ratio })
    end
  end

  describe 'malformed fact values' do
    it 'skips a value the column cannot accept rather than raising' do
      species.update!(maximum_height_cm: nil)
      record('maximum_height_cm', 'not a number')

      expect { described_class.run(dry_run: false) }.not_to raise_error
      expect(species.reload.maximum_height_cm).to be_nil
    end

    it 'counts an unconvertible value instead of losing it from the report' do
      species.update!(maximum_height_cm: nil)
      record('maximum_height_cm', 'not a number')

      expect(described_class.run(dry_run: true).rejected[:unconvertible]).to eq(1)
    end

    # An aggregated fact is a median, so a whole-centimetre column routinely
    # receives a decimal. Integer() refuses it; refusing it dropped 19,662 of
    # the 263,220 TRY facts in the first dry run, all of them good measurements.
    it 'rounds a decimal onto a whole-number column' do
      species.update!(maximum_height_cm: nil)
      record('maximum_height_cm', '16.200000000000003')

      described_class.run(dry_run: false)

      expect(species.reload.maximum_height_cm).to eq(16)
    end

    it 'does not coerce a non-numeric string to zero' do
      species.update!(maximum_height_cm: nil)
      record('maximum_height_cm', 'tall')

      described_class.run(dry_run: false)

      expect(species.reload.maximum_height_cm).to be_nil
    end
  end
  # A count that informs a go/no-go decision must not quietly omit what it did
  # not look at. Facts on attributes the contract excludes never reach the
  # promotion loop, so they are counted and named separately.
  describe 'what it did not consider' do
    it 'reports facts on attributes outside the contract, by attribute' do
      record('human_usage_type', 'food')
      record('soil_ph_indicator', '5')
      record('growth_rate', 'Rapid')

      result = described_class.run(dry_run: true)

      expect(result.out_of_contract).to eq('human_usage_type' => 1, 'soil_ph_indicator' => 1)
      expect(result.out_of_contract.values.sum).to eq(2)
    end

    it 'reports nothing extra when every fact is in the contract' do
      record('growth_rate', 'Rapid')

      expect(described_class.run(dry_run: true).out_of_contract).to be_empty
    end
  end

end
