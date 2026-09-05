require 'rails_helper'

RSpec.describe Migrators::GenusFamilyWorker do

  let(:mapping) { Rails.root.join('tmp/test-genus-family.csv') }

  before do
    File.write(mapping, "Testgenus,Testaceae\nOrphanus,Newfamilyaceae\n")
    # The test seeds insert families and genera with explicit ids, which leaves
    # the primary key sequences behind. Dev and production are in sync; this is
    # a fixture artefact, so realign before creating records here.
    %w[families genuses].each {|t| ActiveRecord::Base.connection.reset_pk_sequence!(t) }
  end

  after { FileUtils.rm_f(mapping) }

  def relative_mapping
    mapping.relative_path_from(Rails.root).to_s
  end

  it 'links a genus that has no family' do
    genus = Genus.create!(name: 'Testgenus')
    family = Family.create!(name: 'Testaceae')

    described_class.new.perform(relative_mapping)

    expect(genus.reload.family_id).to eq(family.id)
  end

  it 'creates the family when it does not exist yet' do
    genus = Genus.create!(name: 'Orphanus')

    expect { described_class.new.perform(relative_mapping) }
      .to change { Family.where(name: 'Newfamilyaceae').count }.by(1)

    expect(genus.reload.family.name).to eq('Newfamilyaceae')
  end

  it 'never touches a genus that already has a family' do
    existing = Family.create!(name: 'Alreadyaceae')
    genus = Genus.create!(name: 'Testgenus', family_id: existing.id)
    Family.create!(name: 'Testaceae')

    described_class.new.perform(relative_mapping)

    expect(genus.reload.family_id).to eq(existing.id)
  end

  it 'reports genera absent from the mapping instead of guessing' do
    Genus.create!(name: 'Unknownus')

    report = described_class.new.perform(relative_mapping)

    expect(report[:unmatched]).to include('Unknownus')
    expect(Genus.find_by(name: 'Unknownus').family_id).to be_nil
  end

  it 'writes nothing on a dry run' do
    genus = Genus.create!(name: 'Testgenus')
    Family.create!(name: 'Testaceae')

    report = described_class.new.perform(relative_mapping, true)

    expect(report[:linked]).to eq(1)
    expect(genus.reload.family_id).to be_nil
  end

  it 'is replayable' do
    genus = Genus.create!(name: 'Testgenus')
    Family.create!(name: 'Testaceae')

    described_class.new.perform(relative_mapping)
    second = described_class.new.perform(relative_mapping)

    expect(second[:linked]).to eq(0)
    expect(genus.reload.family).not_to be_nil
  end

  it 'returns false rather than raising when the mapping is missing' do
    expect(described_class.new.perform('datasets/does-not-exist.csv')).to be(false)
  end

end
