require 'rails_helper'

RSpec.describe Ingester::Converter::Flag do # rubocop:todo Metrics/BlockLength

  it 'Can process a good flag' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      growth_months: 'jan|feb|mar'
    }

    result = Ingester::Converter::Flag.resolve!(hash)
    expect(result).to eq({
      growth_months: %i[jan feb mar]
    })
  end

  it 'Can process several good flags' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      duration: 'annual',
      propagated_by: 'bulbs',
      growth_months: 'mar|apr',
      bloom_months: 'apr|may',
      fruit_months: 'may|jun',
      flower_color: 'yellow|blue',
      fruit_color: 'red|brown',
      foliage_color: 'green',
      edible_part: 'fruits|leaves'
    }

    result = Ingester::Converter::Flag.resolve!(hash)
    expect(result).to eq({
      bloom_months: %i[apr may],
      duration: [:annual],
      edible_part: %i[fruits leaves],
      flower_color: %i[yellow blue],
      foliage_color: [:green],
      fruit_color: %i[red brown],
      fruit_months: %i[may jun],
      growth_months: %i[mar apr],
      propagated_by: [:bulbs]
    })
  end

  it 'Dont crash when no flags' do
    result = Ingester::Converter::Flag.resolve!({})
    expect(result).to eq({})
  end

  it 'Crash when invalid flags' do
    expect do
      Ingester::Converter::Flag.resolve!(
        growth_months: 'prout'
      )
    end.to raise_error(Ingester::Converter::Flag::FlagException)
  end
end
