# Provenance trail of a species attribute (see SpeciesFact):
# which source claims which value, with what level of evidence.
class SpeciesFactSerializer < BaseSerializer

  attributes :attribute_name, :source, :value, :unit,
             :evidence_type, :status, :notes,
             :source_record_id, :source_url,
             :n_observations, :observed_at, :updated_at

end
