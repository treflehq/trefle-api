# Every sourced value (SpeciesFact) across species: filter by field, source,
# status, evidence or species, or list the fields whose active sources
# disagree. Read-only: facts are written by imports and accepted corrections.
class Management::SpeciesFactsController < Management::ManagementController

  FILTERS = %i[attribute_name source status evidence_type].freeze

  def index
    @filters = params.permit(*FILTERS, :species, :disputed).to_h.symbolize_keys.compact_blank
    @species = Species.friendly_or_synonym!(@filters[:species]) if @filters[:species]
    @attribute_counts = counts(:attribute_name)
    @source_counts = counts(:source)
    @pagy, @facts = pagy(filtered.order(id: :desc).preload(:species), items: 100)
  rescue ActiveRecord::RecordNotFound
    redirect_to management_species_facts_path(@filters.except(:species)), alert: "No species “#{@filters[:species]}”."
  end

  private

  def filtered
    scope = SpeciesFact.all
    scope = scope.where(attribute_name: @filters[:attribute_name]) if @filters[:attribute_name]
    scope = scope.where(source: @filters[:source]) if @filters[:source]
    scope = scope.where(status: @filters[:status]) if SpeciesFact.statuses.key?(@filters[:status])
    scope = scope.where(evidence_type: @filters[:evidence_type]) if SpeciesFact.evidence_types.key?(@filters[:evidence_type])
    scope = scope.where(species: @species) if @species
    @filters[:disputed] ? scope.where(id: disputed_ids(scope)) : scope
  end

  # Active facts on a (species, field) where active sources give more than one
  # value.
  def disputed_ids(scope)
    pairs = SpeciesFact.active_status.group(:species_id, :attribute_name).having('COUNT(DISTINCT value) > 1')
      .select(:species_id, :attribute_name)
    table = SpeciesFact.arel_table
    tuple = Arel::Nodes::Grouping.new([table[:species_id], table[:attribute_name]])
    scope.active_status.where(Arel::Nodes::In.new(tuple, pairs.arel)).select(:id)
  end

  # Grouped counts over the whole table are a sequential scan: cached briefly.
  def counts(column)
    Rails.cache.fetch("management/species_facts/counts/#{column}", expires_in: 10.minutes) do
      SpeciesFact.group(column).count.sort_by {|_, n| -n }
    end
  end
end
