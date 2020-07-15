require 'rails_helper'

RSpec.describe Ingester::Converter::CommonName do

  it 'Can process a good name' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      common_name: 'one|two|three'
    }

    result = Ingester::Converter::CommonName.resolve!(hash)
    expect(result[:common_names_attributes]).to include(
      { name: 'one' },
      { name: 'two' },
      { name: 'three' }
    )
  end

  it 'Dont crash when no name' do
    result = Ingester::Converter::CommonName.resolve!({})
    expect(result).to eq({})
  end

end
