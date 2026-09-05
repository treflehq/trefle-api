# Data quality dashboard: fill rates per field, trend over snapshots,
# source conflicts and the prioritized work queue.
class Management::DataQualityController < Management::ManagementController

  def index
    @latest_date = DataQualitySnapshot.maximum(:snapshot_on)

    if @latest_date
      snapshots = DataQualitySnapshot.on(@latest_date)
      @field_rows = snapshots.global.where.not(attribute_name: nil).sort_by {|s| -(s.fill_rate || 0) }
      @aggregate = snapshots.global.find_by(attribute_name: nil)
      @rank_rows = snapshots.where(dimension: 'rank').order(species_count: :desc)
      @source_rows = snapshots.where(dimension: 'source').order(species_count: :desc)
    end

    # Day-by-day progression, so an improvement is visible rather than inferred
    @days = (params[:days] || 30).to_i.clamp(2, 365)
    evolution = Quality::Evolution.new(days: @days)
    @series = evolution.series
    @field_moves = evolution.field_moves

    @priorities = Quality::Priorities.fetch(limit: 50)
    @pending_plausibility_warnings = RecordCorrection.where(
      warning_type: 'Checks::PlausibleValues', change_status: :pending
    ).count
  end

end
