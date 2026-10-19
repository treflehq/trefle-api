require 'rails_helper'

# The test suite seeds a full botanic taxonomy (see spec/support/test_seeds.rb)
# that most specs, including this one, run on top of - so assertions here
# work against deltas (this presenter's counts before/after adding fixtures)
# rather than absolute totals.
RSpec.describe HomeStatsPresenter do
  subject(:presenter) { described_class.new }

  let(:genus) { create(:genus) }

  def build_species(rank: 'species', **attrs)
    create(:species, genus_id: genus.id, rank: rank, **attrs)
  end

  describe '#records_by_rank' do
    it 'counts species per rank, labelled, on top of whatever already exists' do
      baseline = presenter.records_by_rank

      build_species(rank: 'species')
      build_species(rank: 'species')
      build_species(rank: 'var', scientific_name: "#{genus.name} testalpha var. testbeta")

      updated = presenter.records_by_rank

      expect(updated['Species']).to eq(baseline['Species'] + 2)
      expect(updated['Varieties']).to eq(baseline['Varieties'] + 1)
      expect(updated.except('Species', 'Varieties')).to eq(baseline.except('Species', 'Varieties'))
    end
  end

  describe 'RANK_LABELS' do
    it 'labels every rank of the enum, subvar as subvarieties (not cultivars)' do
      expect(described_class::RANK_LABELS.keys).to match_array(Species.ranks.keys)
      expect(described_class::RANK_LABELS['subvar']).to eq('Subvarieties')
      expect(described_class::RANK_LABELS.values).not_to include('Cultivars')
    end
  end

  describe '#synonyms_count' do
    it 'counts synonyms on top of whatever already exists' do
      baseline = presenter.synonyms_count

      species = build_species
      Synonym.create!(record: species, name: 'Foo bar L.')
      Synonym.create!(record: species, name: 'Baz qux L.')

      expect(presenter.synonyms_count).to eq(baseline + 2)
    end
  end

  describe 'FIELD_COMPLETENESS_GROUPS' do
    it 'flags a species with every field filled, and excludes an entirely empty one' do
      complete = build_species(
        bibliography: 'Some source', author: 'L.', images_count: 3,
        vegetable: true, light: 4
      )
      SpeciesDistribution.create!(species: complete, zone: Zone.first)
      CommonName.create!(record: complete, name: 'Something')
      empty = build_species

      described_class::FIELD_COMPLETENESS_GROUPS.each do |label, scope_builder|
        ids = scope_builder.call(Species).pluck(:id)
        expect(ids).to include(complete.id), "expected '#{label}' to include the fully-filled species"
        expect(ids).not_to include(empty.id), "expected '#{label}' to exclude the empty species"
      end
    end
  end

  describe '#field_completeness_shares' do
    it 'returns one percentage per group, between 0 and 100' do
      shares = presenter.field_completeness_shares

      expect(shares.keys).to eq(described_class::FIELD_COMPLETENESS_GROUPS.keys)
      expect(shares.values).to all(be_between(0, 100))
    end
  end

  describe '#correction_activity' do
    let(:species) { build_species }

    def corrected(status:, created_at:, updated_at: created_at, user: create(:user), correction: { year: 1900 })
      correction = create(:record_correction, record: species, user: user, change_status: status,
                                              correction_json: { scientific_name: species.scientific_name, **correction }.to_json)
      correction.update_columns(created_at: created_at, updated_at: updated_at, decided_at: status == :pending ? nil : updated_at)
      correction
    end

    it 'only counts submitted/accepted/contributors inside the 30-day window' do
      baseline = presenter.correction_activity
      recent_contributor = create(:user)
      corrected(status: :pending, created_at: 5.days.ago, user: recent_contributor)
      corrected(status: :accepted, created_at: 10.days.ago, updated_at: 3.days.ago, user: create(:user))
      # Outside the 30-day window - must not count as submitted/accepted/contributor.
      # Still within the 12-week series window, so it does show up there.
      corrected(status: :accepted, created_at: 40.days.ago, updated_at: 40.days.ago)

      activity = presenter.correction_activity

      expect(activity[:submitted]).to eq(baseline[:submitted] + 2)
      expect(activity[:accepted]).to eq(baseline[:accepted] + 1)
      expect(activity[:fields_completed]).to eq(baseline[:fields_completed] + 1)
      expect(activity[:contributors]).to eq(baseline[:contributors] + 2)
    end

    it 'counts only what people filed as submitted and contributors, not the checks and audits' do
      baseline = presenter.correction_activity
      person = create(:user)
      corrected(status: :pending, created_at: 2.days.ago, user: person)
      create(:record_correction, record: species, user: person, warning_type: 'report', source_type: :report)
      create(:record_correction, record: species, user: create(:user), warning_type: 'Audit::YearDiffers')
      create(:record_correction, record: species, user: create(:user), warning_type: 'Checks::FactDivergence')

      activity = presenter.correction_activity

      expect(activity[:submitted]).to eq(baseline[:submitted] + 2)
      expect(activity[:contributors]).to eq(baseline[:contributors] + 1)
    end

    it 'counts the fields the accepted corrections set, the name excepted' do
      baseline = presenter.correction_activity[:fields_completed]

      corrected(status: :accepted, created_at: 2.days.ago, correction: { light: 7, maximum_height_cm: 300 })
      corrected(status: :rejected, created_at: 2.days.ago, correction: { year: 1901 })

      expect(presenter.correction_activity[:fields_completed]).to eq(baseline + 2)
    end

    it 'dates a decision when it was taken, not when the row was last edited' do
      baseline = presenter.correction_activity[:accepted]
      old = corrected(status: :accepted, created_at: 60.days.ago, updated_at: 60.days.ago)

      old.update!(notes: 'edited today')

      expect(presenter.correction_activity[:accepted]).to eq(baseline)
    end

    it 'counts the corrections reviewed in the window, accepted or rejected' do
      baseline = presenter.correction_activity[:reviewed]

      corrected(status: :accepted, created_at: 40.days.ago, updated_at: 2.days.ago)
      corrected(status: :rejected, created_at: 3.days.ago, updated_at: 1.day.ago)
      corrected(status: :pending, created_at: 1.day.ago)
      corrected(status: :rejected, created_at: 50.days.ago, updated_at: 45.days.ago)

      expect(presenter.correction_activity[:reviewed]).to eq(baseline + 2)
    end
  end

  describe '#latest_reviewed_corrections' do
    it 'returns the most recently reviewed corrections first, excluding pending ones' do
      species = build_species
      user = create(:user, name: 'Ada')

      old_accepted = create(:record_correction, record: species, user: user, change_status: :accepted,
                                                correction_json: { author: 'L.' }.to_json)
      old_accepted.update_columns(updated_at: 2.days.ago, decided_at: 2.days.ago)

      recent_rejected = create(:record_correction, record: species, user: user, change_status: :rejected)
      recent_rejected.update_columns(updated_at: 1.hour.ago, decided_at: 1.hour.ago)

      create(:record_correction, record: species, user: user, change_status: :pending)

      entries = presenter.latest_reviewed_corrections
      by_species = entries.select {|e| e[:species_slug] == species.slug }

      expect(by_species.length).to eq(2)
      expect(by_species.first).to include(
        species_name: species.scientific_name,
        species_slug: species.slug,
        status: 'rejected',
        contributor: 'Ada'
      )
      expect(by_species.last).to include(status: 'accepted', description: a_string_including('author'))
    end

    it 'falls back to the GitHub username, then the email, when the user has no name' do
      species = build_species
      user = create(:user, name: nil, github_username: 'octocat')
      correction = create(:record_correction, record: species, user: user, change_status: :accepted)
      correction.update_columns(updated_at: 1.hour.ago)

      entry = presenter.latest_reviewed_corrections.find {|e| e[:species_slug] == species.slug }
      expect(entry[:contributor]).to eq('octocat')
    end
  end
end
