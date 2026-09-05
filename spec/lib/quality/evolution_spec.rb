require 'rails_helper'

RSpec.describe Quality::Evolution do

  def snapshot(date, filled:, fields: 10, species: 100, conflicts: 0, per_field: {})
    DataQualitySnapshot.create!(
      snapshot_on: date, dimension: 'global', dimension_value: nil, attribute_name: nil,
      species_count: species, filled_count: filled, conflict_count: conflicts,
      details: { fields_count: fields, avg_completion_ratio: 4.0 }
    )
    per_field.each do |field, count|
      DataQualitySnapshot.create!(
        snapshot_on: date, dimension: 'global', dimension_value: nil, attribute_name: field.to_s,
        species_count: species, filled_count: count
      )
    end
  end

  describe '#series' do
    it 'returns one point per day, oldest first' do
      snapshot(2.days.ago.to_date, filled: 100)
      snapshot(1.day.ago.to_date, filled: 150)
      snapshot(Date.current, filled: 200)

      dates = described_class.new(days: 30).series.map(&:date)

      expect(dates).to eq([2.days.ago.to_date, 1.day.ago.to_date, Date.current])
    end

    it 'expresses progress as the share of measurable cells that are filled' do
      # 100 species x 10 fields = 1000 cells, 250 filled
      snapshot(Date.current, filled: 250, fields: 10, species: 100)

      expect(described_class.new(days: 30).series.first.fill_rate).to eq(25.0)
    end

    it 'reports no fill rate rather than a wrong one when the shape is unknown' do
      DataQualitySnapshot.create!(
        snapshot_on: Date.current, dimension: 'global', attribute_name: nil,
        species_count: 100, filled_count: 250, details: {}
      )

      expect(described_class.new(days: 30).series.first.fill_rate).to be_nil
    end

    it 'ignores snapshots outside the window' do
      snapshot(40.days.ago.to_date, filled: 100)
      snapshot(Date.current, filled: 200)

      expect(described_class.new(days: 30).series.length).to eq(1)
    end
  end

  describe '#field_moves' do
    it 'reports what each field gained between the ends of the window' do
      snapshot(2.days.ago.to_date, filled: 100, per_field: { light: 10, ph_minimum: 50 })
      snapshot(Date.current, filled: 200, per_field: { light: 40, ph_minimum: 50 })

      moves = described_class.new(days: 30).field_moves

      expect(moves.map(&:field)).to eq(['light'])
      expect(moves.first.delta).to eq(30)
    end

    it 'surfaces a regression, not only progress' do
      snapshot(2.days.ago.to_date, filled: 100, per_field: { light: 40 })
      snapshot(Date.current, filled: 90, per_field: { light: 10 })

      expect(described_class.new(days: 30).field_moves.first.delta).to eq(-30)
    end

    it 'orders by how much moved, regardless of direction' do
      snapshot(2.days.ago.to_date, filled: 100, per_field: { light: 100, toxicity: 5 })
      snapshot(Date.current, filled: 100, per_field: { light: 50, toxicity: 15 })

      expect(described_class.new(days: 30).field_moves.map(&:field)).to eq(%w[light toxicity])
    end

    it 'says nothing when there is only one point to compare' do
      snapshot(Date.current, filled: 100, per_field: { light: 10 })

      expect(described_class.new(days: 30).field_moves).to be_empty
    end
  end

end
