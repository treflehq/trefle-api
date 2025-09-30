require 'rails_helper'

RSpec.describe Ingester do # rubocop:todo Metrics/BlockLength

  # it 'Can process a hash' do

  #   hash = {
  #     scientific_name: 'Aiphanes adadea',
  #     rank: 'species',
  #     author: 'Borchs. & Balslev',
  #     genus: Genus.last.name,
  #     status: 'accepted',
  #     sources_gbif: 2_738_693,
  #     confidence: 98,
  #     average_height_value: 2100,
  #     average_height_unit: 'cm'
  #   }

  #   result = Ingester.from_hash(hash)
  #   pp result

  #   expect(result).to be_a(Hash)
  #   expect(result[:changes]).to include({
  #     'average_height_unit' => [nil, 'cm'],
  #     'genus_id' => [nil, Genus.last.id],
  #     'scientific_name' => [nil, 'Aiphanes adadea']
  #   })
  #   expect(result[:errors]).to eq([])
  # end

  it 'Can process a big hash with incomplete data' do # rubocop:todo Metrics/BlockLength

    hash = {
      image_url: 'https://s3.amazonaws.com/openfarm-project/production/media/pictures/attachments/54a9de1233316500020c0000.jpg?1420418576',
      source_gbif: '3152707',
      source_openfarm: '542e9c226331360002030f00',
      scientific_name: 'Abelmoschus nonexistus',
      rank: 'species',
      genus: Genus.last.name,
      year: nil,
      author: 'Moench',
      common_name: 'Okra|Bonnie Green Okra Heirloom Clemson Spineless',
      observations: 'Vegetal flavour, Medium-yellow flowers',
      days_to_harvest: 30,
      flower_color: 'yellow',
      flower_conspicuous: true,
      foliage_color: 'green|blue',
      foliage_texture: nil,
      fruit_color: nil,
      fruit_conspicuous: nil,
      fruit_months: 'jan|feb|mar',
      bloom_months: nil,
      ground_humidity: nil,
      growth_form: nil,
      growth_habit: nil,
      growth_months: nil,
      growth_rate: nil,
      edible_part: 'flowers',
      vegetable: nil,
      light: 8,
      soil_nutriments: 8,
      soil_salinity: 8,
      planting_sowing_description: 'Direct seed indoors or outside',
      adapted_to_coarse_textured_soils: nil,
      adapted_to_fine_textured_soils: nil,
      adapted_to_medium_textured_soils: nil,
      anaerobic_tolerance: nil,
      atmospheric_humidity: nil,
      average_height_unit: 'cm',
      average_height_value: '250',
      bibliography: nil,
      ph_maximum: nil,
      ph_minimum: nil,
      planting_days_to_harvest: 120,
      planting_description: 'Plant carefully',
      planting_row_spacing_cm: '25',
      planting_spread_cm: '25'
    }

    result = Ingester.from_hash(hash)

    pp result
    expect(result).to be_a(Hash)
    expect(result[:changes]['scientific_name']).to eq([nil, 'Abelmoschus nonexistus'])
    expect(result[:changes]['flower_conspicuous']).to eq([nil, true])
    expect(result[:changes]['genus_id']).to eq([nil, Genus.last.id])
    expect(result[:changes]['observations']).to eq([nil, 'Vegetal flavour, Medium-yellow flowers'])
    expect(result[:changes]['average_height_cm']).to eq([nil, 0.25e3])
    # expect(result[:changes]['average_height_unit']).to eq([nil, 'cm'])
    expect(result[:changes]['rank']).to eq([nil, 'species'])
    expect(result[:changes]['fruit_months']).to eq([0, 7])
    expect(result[:changes]['flower_color']).to eq([0, 16])
    expect(result[:changes]['light']).to eq([nil, 8])
    expect(result[:changes]['soil_nutriments']).to eq([nil, 8])
    expect(result[:changes]['soil_salinity']).to eq([nil, 8])
    expect(result[:changes]['foliage_color']).to eq([0, 320])
    expect(result[:changes]['token']).to eq([nil, 'abelmoschus nonexistus'])
    expect(result[:changes]['full_token']).to eq([nil, 'abelmoschus nonexistus'])
    expect(result[:changes]['planting_description']).to eq([nil, 'Plant carefully'])
    expect(result[:changes]['planting_sowing_description']).to eq([nil, 'Direct seed indoors or outside'])
    expect(result[:changes]['planting_days_to_harvest']).to eq([nil, 120])
    expect(result[:changes]['planting_row_spacing_cm']).to eq([nil, 25])
    expect(result[:changes]['planting_spread_cm']).to eq([nil, 25])
    expect(result[:errors]).to eq([])
    sp = Species.friendly.find('abelmoschus-nonexistus')
    expect(sp.foreign_sources.pluck(:name)).to include('GBIF', 'openfarm')
    expect(sp.common_names.pluck(:name)).to include('Okra', 'Bonnie Green Okra Heirloom Clemson Spineless')
  end
end
