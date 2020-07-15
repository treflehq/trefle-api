require 'rails_helper'

RSpec.describe Ingester::Converter::Source do # rubocop:todo Metrics/BlockLength

  it 'Can process a good source' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      source_gbif: '1234'
    }

    result = Ingester::Converter::Source.resolve!(hash)
    expect(result[:foreign_sources_plants_attributes][0]).to include({
      fid: '1234',
      foreign_source_id: ForeignSource.find_by_slug('gbif').id
    })
  end

  it 'Can process an unknown source' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      source_mamamia: '2345'
    }

    result = Ingester::Converter::Source.resolve!(hash)
    expect(result[:foreign_sources_plants_attributes][0]).to include({
      fid: '2345',
      foreign_source_id: ForeignSource.find_by_slug('mamamia').id
    })
  end

  it 'Dont crash when no sources' do
    result = Ingester::Converter::Source.resolve!({})
    expect(result).to eq({})
  end

  # it 'Crash when invalid sources' do
  #   expect do
  #     Ingester::Converter::Source.resolve!(
  #       source_url: 'prout'
  #     )
  #   end.to raise_error(Ingester::Converter::Source::SourceException)
  # end
end
