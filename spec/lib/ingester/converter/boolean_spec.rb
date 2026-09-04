require 'rails_helper'

RSpec.describe Ingester::Converter::Boolean do

  it 'passes real booleans through' do
    result = described_class.resolve!({ edible: true, vegetable: false })

    expect(result).to eq(edible: true, vegetable: false)
  end

  it 'parses the "true" and "false" strings, whatever their case' do
    result = described_class.resolve!({
      edible: 'true',
      vegetable: 'FALSE',
      flower_conspicuous: 'True'
    })

    expect(result).to eq(edible: true, vegetable: false, flower_conspicuous: true)
  end

  it 'keeps false, which is information, and drops nil, which is not' do
    result = described_class.resolve!({ leaf_retention: false, known_allelopath: nil })

    expect(result).to eq(leaf_retention: false)
  end

  it 'converts every boolean field it knows about' do
    hash = described_class::FIELDS.index_with { true }

    expect(described_class.resolve!(hash).keys).to match_array(described_class::FIELDS)
  end

  it 'ignores fields it does not own' do
    result = described_class.resolve!({ scientific_name: 'Abies alba', light: 4, edible: true })

    expect(result).to eq(edible: true)
  end

  it 'does not crash on an empty hash' do
    expect(described_class.resolve!({})).to eq({})
  end

  # Documents current behaviour: an unparseable string is passed through as-is
  # and it is ActiveRecord's cast that decides. Worth knowing before routing a
  # pipeline that emits "yes"/"no".
  it 'passes an unrecognized string through unchanged' do
    expect(described_class.resolve!({ edible: 'yes' })).to eq(edible: 'yes')
  end

end
