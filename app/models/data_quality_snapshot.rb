# A dated data-quality measurement, written by `rake quality:snapshot`.
# One row per (date, dimension, dimension_value, attribute); attribute_name is
# nil for the aggregate row of a dimension.
class DataQualitySnapshot < ApplicationRecord

  validates :snapshot_on, presence: true
  validates :dimension, presence: true

  scope :on, ->(date) { where(snapshot_on: date) }
  scope :global, -> { where(dimension: 'global') }

  def fill_rate
    return nil if species_count.zero?

    (filled_count.to_f / species_count * 100).round(1)
  end

end
