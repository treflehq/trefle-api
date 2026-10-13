# GET /api/v1/species/:species_id/synonyms
#
# The paginated list of a species' synonyms. The species detail only embeds
# the first SpeciesSerializer::SYNONYMS_LIMIT of them (Rosa canina carries
# 1,052: 628 KB of a 641 KB payload); this is where a client reads the rest.
# Includes the synonyms attached to the species' autonyms, each row saying
# which record it hangs on (`attached_to`) -- see Species#synonyms_with_autonyms.
class Api::V1::SynonymsController < Api::ApiController

  def index
    @resource = Species.friendly_or_synonym!(params[:species_id])
    @collection = collection

    links = collection_links(@collection, name: %i[species synonyms])

    render_serialized_collection(
      @collection,
      SynonymSerializer,
      links: links,
      meta: {
        species: {
          id: @resource.id,
          slug: @resource.slug,
          scientific_name: @resource.scientific_name
        }
      }
    )
  end

  def collection
    return @collection if @collection

    @collection = @resource.synonyms_with_autonyms
      .order(:name, :id)
      .preload(foreign_sources_plants: :foreign_source)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end
