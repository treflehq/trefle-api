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
      plant: Plant.schema,
      plant_light: Plant.light_schema,
      species: Species.schema,
      species_light: Species.light_schema,
      source: Source.schema,
      correction: RecordCorrection.schema,
      zone: Zone.schema,
      request_body_correction: RecordCorrection.request_body,
      filters_families: Family.filters,
      filters_genus: Genus.filters,
      filters_plants: Species.filters,
      filters_species: Species.filters,
      filters_not_species: Species.filters_not,
      sorts_families: Family.sorts,
      sorts_genus: Genus.sorts,
      sorts_plants: Species.sorts,
      sorts_species: Species.sorts,
      ranges_plants: Species.ranges,
      ranges_species: Species.ranges
    }.freeze
  end
end
