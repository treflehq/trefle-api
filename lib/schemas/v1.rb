module Schemas
  module V1
    SCHEMAS = {
      kingdom: Kingdom.schema,
      subkingdom: Subkingdom.schema,
      division: Division.schema,
      division_class: DivisionClass.schema,
      division_order: DivisionOrder.schema,
      family: Family.schema,
      genus: Genus.schema,
      # No plant_light: plant lists (/plants, /genus/{id}/plants,
      # /distributions/{id}/plants, /plants/search) render each plant's main
      # species with SpeciesLightSerializer, i.e. species_light.
      plant: Plant.schema,
      species: Species.schema,
      species_light: Species.light_schema,
      synonym: Synonym.schema,
      source: Source.schema,
      correction: RecordCorrection.schema,
      species_fact: SpeciesFact.schema,
      user_profile: UserProfile.schema,
      api_status: ApiStatus.schema,
      zone: Zone.schema,
      error: Error.schema,
      request_body_correction: RecordCorrection.request_body
    }.freeze

    # components.parameters -- see Parameters for why filter/order/range are
    # declared there rather than as plain schemas.
    PARAMETERS = Parameters.all.freeze
  end
end
