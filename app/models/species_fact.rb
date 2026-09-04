# A sourced value for one species attribute. The species columns are a
# projection of the strongest active fact per attribute (see
# Ingester::FactsRecorder); facts keep the full provenance trail.
class SpeciesFact < ApplicationRecord

  belongs_to :species

  validates :attribute_name, presence: true
  validates :source, presence: true

  enum :evidence_type, {
    reported: 0, # asserted by an external database, not independently measured
    measured: 1, # backed by referenced measurements (e.g. TRY observations)
    derived: 2,  # computed by us from primary data, documented method
    inferred: 3  # imputed (e.g. from congeneric species)
  }, suffix: true

  # A losing claim stays "active" (it is still what that source says): the
  # projected column value is simply the strongest active fact, and differing
  # active facts on one attribute are the conflict list.
  enum :status, {
    active: 0,     # current claim from this source
    superseded: 1, # replaced by a newer claim from the same source
    rejected: 2    # failed plausibility validation, never projected
  }, suffix: true

  scope :for_attribute, ->(name) { where(attribute_name: name) }

  # Records a value coming from a source. An :active fact supersedes this
  # source's previous active fact for the attribute. Returns the created fact.
  def self.record!(species:, attribute_name:, source:, value:, status: :active, **attrs)
    if status.to_sym == :active
      where(species: species, attribute_name: attribute_name, source: source, status: :active)
        .find_each {|f| f.update!(status: :superseded) }
    end

    create!(
      species: species,
      attribute_name: attribute_name,
      source: source,
      value: value&.to_s,
      value_numeric: value.is_a?(Numeric) ? value : nil,
      unit: Traits.field(attribute_name)&.dig('unit'),
      status: status,
      **attrs
    )
  end

  # Active facts disagreeing on the same attribute of the same species
  def conflicting_facts
    species.species_facts.active_status.for_attribute(attribute_name).where.not(id: id).where.not(value: value)
  end

end
