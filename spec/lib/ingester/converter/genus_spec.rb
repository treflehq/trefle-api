require 'rails_helper'

RSpec.describe Ingester::Converter::Genus do # rubocop:todo Metrics/BlockLength

  let (:genus) { Genus.all.sample }

  it 'Can process a genus id' do

    result = Ingester::Converter::Genus.resolve!(
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus_id: genus.id
    )

    expect(result).to eq({
      genus_id: genus.id
    })

  end

  it 'Can process a genus name' do

    result = Ingester::Converter::Genus.resolve!(
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: genus.name
    )

    expect(result).to eq({
      genus_id: genus.id
    })

  end

  it 'Crash on an invalid genus id' do

    expect do
      Ingester::Converter::Genus.resolve!(
        rank: 'species',
        author: 'Borchs. & Balslev',
        genus_id: -2
      )
    end.to raise_error(ActiveRecord::RecordNotFound)

  end

  it 'Crash when no genus' do
    expect do
      Ingester::Converter::Genus.resolve!(
        rank: 'species',
        author: 'Borchs. & Balslev',
        genus: 'donotexists'
      )
    end.to raise_error(Ingester::Converter::Genus::GenusException)
  end
end
