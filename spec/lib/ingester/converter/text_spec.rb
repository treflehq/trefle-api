require 'rails_helper'

RSpec.describe Ingester::Converter::Text do # rubocop:todo Metrics/BlockLength

  it 'Can process a good text field' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      observations: 'A good observation'
    }

    result = Ingester::Converter::Text.resolve!(hash)
    expect(result).to include(
      observations: 'A good observation'
    )
  end
  it 'Can process all text fields' do # rubocop:todo Metrics/BlockLength

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      anaerobic_tolerance: 'low',
      c_n_ratio: 'medium',
      caco_3_tolerance: 'high',
      family_common_name: 'Nebula',
      growth_form: 'tree',
      growth_habit: 'shrub',
      growth_rate: 'slow',
      lifespan: 'long',
      maturation_order: 'first',
      nitrogen_fixation: 'low',
      protein_potential: 'high',
      shape_and_orientation: 'erected',
      bibliography: 'A bibloio',
      observations: 'Very big',
      planting_description: 'good fruits',
      planting_sowing_description: 'Sow carefully',
      biological_type_raw: 'no idea',
      dissemination_raw: 'pollen',
      fruit_shape_raw: 'bubble',
      inflorescence_raw: 'bla bla',
      maturation_order_raw: 'mama mia',
      pollinisation_raw: 'okay',
      sexuality_raw: 'nope'
    }

    result = Ingester::Converter::Text.resolve!(hash)
    expect(result).to include(
      anaerobic_tolerance: 'low',
      c_n_ratio: 'medium',
      caco_3_tolerance: 'high',
      family_common_name: 'Nebula',
      growth_form: 'tree',
      growth_habit: 'shrub',
      growth_rate: 'slow',
      lifespan: 'long',
      maturation_order: 'first',
      nitrogen_fixation: 'low',
      protein_potential: 'high',
      shape_and_orientation: 'erected',
      bibliography: 'A bibloio',
      observations: 'Very big',
      planting_description: 'good fruits',
      planting_sowing_description: 'Sow carefully',
      biological_type_raw: 'no idea',
      dissemination_raw: 'pollen',
      fruit_shape_raw: 'bubble',
      inflorescence_raw: 'bla bla',
      maturation_order_raw: 'mama mia',
      pollinisation_raw: 'okay',
      sexuality_raw: 'nope'
    )
  end

  it 'Dont crash when no name' do
    result = Ingester::Converter::Text.resolve!({})
    expect(result).to eq({})
  end

end
