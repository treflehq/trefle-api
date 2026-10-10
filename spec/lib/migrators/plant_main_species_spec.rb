require 'rails_helper'

RSpec.describe Migrators::PlantMainSpecies do
  let(:genus) { create(:genus) }

  def plant_with(*names, plant_name: names.first)
    plant = Plant.create!(scientific_name: plant_name, genus: genus)
    species = names.map do |n|
      sp = Species.new(scientific_name: n, genus: genus, plant: plant, rank: :species)
      sp.save!(validate: false)
      sp
    end
    plant.update_columns(main_species_id: nil)
    [plant, species]
  end

  it 'links a plant to its only root species' do
    plant, (root,) = plant_with("#{genus.name} unica")

    result = described_class.run(dry_run: false)

    expect(plant.reload.main_species_id).to eq(root.id)
    expect(result.linked).to be >= 1
  end

  it 'picks the root carrying the plant name when there are several' do
    plant, (named, _other) = plant_with("#{genus.name} prima", "#{genus.name} secunda")

    described_class.run(dry_run: false)

    expect(plant.reload.main_species_id).to eq(named.id)
  end

  it 'leaves an ambiguous plant alone and reports it' do
    plant, = plant_with("#{genus.name} alfa", "#{genus.name} beta", plant_name: "#{genus.name} gamma")

    result = described_class.run(dry_run: false)

    expect(plant.reload.main_species_id).to be_nil
    expect(result.ambiguous_sample).to include("#{genus.name} gamma")
  end

  it 'counts an empty plant without touching it' do
    plant = Plant.create!(scientific_name: "#{genus.name} vacua", genus: genus)

    result = described_class.run(dry_run: false)

    expect(plant.reload.main_species_id).to be_nil
    expect(result.empty).to be >= 1
  end

  it 'writes nothing on a dry run' do
    plant, = plant_with("#{genus.name} sicca")

    described_class.run

    expect(plant.reload.main_species_id).to be_nil
  end

  it 'links the plant when a root species is created' do
    plant = Plant.create!(scientific_name: "#{genus.name} nova", genus: genus)
    species = Species.create!(scientific_name: "#{genus.name} nova", genus: genus, plant: plant, rank: :species)

    expect(plant.reload.main_species_id).to eq(species.id)
  end
end
