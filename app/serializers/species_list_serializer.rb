# A species row of a list when the request picks its `fields`
# (SparseFieldsets): any field of the detail (SpeciesSerializer) can be asked
# for on a list, `growth` or `distributions` included, so that reading the
# traits of a page no longer takes one detail call per species.
#
# Without `fields`, lists keep SpeciesLightSerializer. The fields both
# serializers have are rendered the light way here, so that a field reads
# the same whichever serializer a request lands on: `synonyms_count` is the
# counter column (no per-row query), `links` tolerate a species without a
# plant. `synonyms` cannot be asked for on a list (FIELDS): a species can
# have a thousand of them, `links.synonyms` pages through them.
class SpeciesListSerializer < SpeciesSerializer
  # The fields a list request can ask for.
  def self.field_filters
    super.except('synonyms')
  end

  delegate :synonyms_count, to: :object

  def links
    {
      self: url_helpers.api_v1_species_path(object),
      plant: url_helpers.api_v1_plant_path(object&.plant&.slug || 'unknown'),
      genus: url_helpers.api_v1_genus_path(object&.genus&.slug || 'unknown'),
      synonyms: url_helpers.api_v1_species_synonyms_path(object)
    }
  end
end
