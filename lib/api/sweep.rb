module Api
  # Enumerates the public API surface as request paths, so a sweep can both
  # keep the cache warm and notice an endpoint that started returning 500.
  #
  # The surface splits in two, and they want different treatment:
  #
  #   shape  — every collection crossed with every filter, order and range key
  #            it accepts. Bounded (a few hundred paths) and worth covering on
  #            every run: this is what catches a filter that raises.
  #   depth  — pagination and individual records. Unbounded — 489k species is
  #            24k index pages — so a run takes a slice and the next run picks
  #            up where it left off.
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

    # Pagination and individual records, in demand order. Returns `limit` paths
    # starting at `cursor`, so consecutive runs advance through the surface.
    def self.depth_paths(cursor, limit)
      all = paginated_paths + record_paths
      return [] if all.empty?

      start = cursor % all.length
      all.rotate(start).first(limit)
    end

    # Deep pages matter: a bug in page 900 of species is invisible from page 1.
    def self.paginated_paths
      %w[species plants genus families distributions].flat_map do |path|
        [2, 5, 20, 100, 500].map {|page| "/api/v1/#{path}?page=#{page}" }
      end
    end

    def self.record_paths
      Species.order(gbif_score: :desc).limit(400).pluck(:slug).map {|s| "/api/v1/species/#{s}" } +
        Plant.order(main_species_gbif_score: :desc).limit(200).pluck(:slug).map {|s| "/api/v1/plants/#{s}" }
    end
  end
end
