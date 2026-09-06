module Api
  # Enumerates the public API surface as request paths, so a sweep can both
  # keep the cache warm and notice an endpoint that started returning 500.
  #
  # The surface splits in three, and they want different treatment:
  #
  #   shape  — every collection crossed with every filter, order and range key
  #            it accepts. Bounded (a few hundred paths) and worth covering on
  #            every run: this is what catches a filter that raises.
  #   hot    — the most-requested records, also every run. Warming is only
  #            useful for things people actually ask for.
  #   depth  — *everything else*: every index page of every collection and
  #            every record. Around a million paths, so a run takes a slice and
  #            the next resumes exactly where it stopped.
  module Sweep
    # Collections and the controller that serves them, for reading the keys
    # each one actually accepts rather than guessing.
    COLLECTIONS = {
      'kingdoms' => nil,
      'subkingdoms' => nil,
      'divisions' => nil,
      'division_classes' => nil,
      'division_orders' => nil,
      'families' => 'Api::V1::FamiliesController',
      'genus' => 'Api::V1::GenusController',
      'plants' => 'Api::V1::PlantsController',
      'species' => 'Api::V1::SpeciesController',
      'distributions' => 'Api::V1::ZonesController',
      'corrections' => 'Api::V1::RecordCorrectionsController'
    }.freeze

    HOT_RECORDS = 150

    # A value of the right shape for each column type. What matters for error
    # detection is that the key is exercised and the value parses — not that it
    # matches any row.
    def self.sample_value(field)
      column = Species.columns_hash[field.to_s] || Plant.columns_hash[field.to_s]
      case column&.type
      when :boolean then 'true'
      when :integer, :bigint then '1'
      when :float, :decimal then '1.5'
      when :datetime, :date then '2020-01-01'
      else 'a'
      end
    end

    def self.constant_for(controller, name)
      controller&.safe_constantize&.const_get(name, false)
    rescue NameError
      nil
    end

    # Every collection index, then every filter/order/range key it accepts.
    def self.shape_paths
      COLLECTIONS.flat_map do |path, controller|
        base = "/api/v1/#{path}"
        [base] + filter_paths(base, controller) + order_paths(base, controller) + range_paths(base, controller)
      end
    end

    def self.filter_paths(base, controller)
      fields = constant_for(controller, :FILTERABLE_FIELDS) || []
      not_fields = constant_for(controller, :FILTERABLE_NOT_FIELDS) || []
      fields.map {|f| "#{base}?filter[#{f}]=#{sample_value(f)}" } +
        not_fields.first(5).map {|f| "#{base}?filter_not[#{f}]=null" }
    end

    def self.order_paths(base, controller)
      (constant_for(controller, :ORDERABLE_FIELDS) || []).flat_map do |f|
        ["#{base}?order[#{f}]=asc", "#{base}?order[#{f}]=desc"]
      end
    end

    def self.range_paths(base, controller)
      (constant_for(controller, :RANGEABLE_FIELDS) || []).map {|f| "#{base}?range[#{f}]=1,100" }
    end

    # The records people actually request, warmed on every run. The full walk
    # below will reach them too, but only once per cycle — which is weeks.
    def self.hot_paths
      species = Species.order(gbif_score: :desc).limit(HOT_RECORDS).pluck(:slug).compact
      plants = Plant.order(main_species_gbif_score: :desc).limit(HOT_RECORDS / 2).pluck(:slug).compact

      species.map {|slug| "/api/v1/species/#{slug}" } + plants.map {|slug| "/api/v1/plants/#{slug}" }
    end
  end
end
