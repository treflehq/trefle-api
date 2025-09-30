# Will help up migrate our new flags
module Migrators
  class Flags

    def self.run
      Species.where.not(duration: nil).where(duration_fl: 0).each do |species|
        update_species(species)
      end

      Species.where(complete_data: true, growth_months: 0).each do |species|
        update_species(species)
      end
    end

    def self.update_species(species)
      species.duration_fl ||= duration_string_to_flags(species.duration)
      species.growth_months ||= string_period_to_months_array(species.active_growth_period)
      species.fruit_months ||= [
        string_period_to_months_array(species.fruit_seed_period_begin),
        string_period_to_months_array(species.fruit_seed_period_end)
      ].flatten.uniq
      species.bloom_months ||= string_period_to_months_array(species.bloom_period)
      species.save
    end

    def self.propagated_by(species)
      {
        bare_root: species.propagated_by_bare_root == true,
        bulbs: species.propagated_by_bulbs == true,
        container: species.propagated_by_container == true,
        corms: species.propagated_by_corms == true,
        cuttings: species.propagated_by_cuttings == true,
        seed: species.propagated_by_seed == true,
        sod: species.propagated_by_sod == true,
        sprigs: species.propagated_by_sprigs == true,
        tubers: species.propagated_by_tubers == true
      }.select {|_k, v| v }.keys
    end

    def self.migrate_duration(species)
      species.duration_fl = duration_string_to_flags(species.duration)
    end

    def self.duration_string_to_flags(duration)
      return [] if duration.blank?

      duration.gsub('AN', 'Annual').split(',').map(&:strip).map(&:underscore).map(&:to_sym)
    end

    def self.string_period_to_months_array(period)
      table = {
        'fall' => %i[sep oct nov],
        'winter' => %i[dec jan feb],
        'late winter' => %i[jan feb mar],
        'early spring' => %i[feb mar apr],
        'mid spring' => %i[mar apr may],
        'spring' => %i[mar apr may],
        'late spring' => %i[apr may jun],
        'early summer' => %i[may jun jul],
        'summer' => %i[jun jul aug],
        'mid summer' => %i[jun jul aug],
        'late summer' => %i[jul aug sep],
        'year round' => %i[jan feb mar apr may jun jul aug sep oct nov dec]
      }
      period_keys = period&.split(/,|and/)&.map {|p| p&.split(/,|and/)&.map(&:strip)&.map(&:underscore) }
      period_keys.map {|p| table[p] }.uniq.flatten.compact
    end
  end
end
