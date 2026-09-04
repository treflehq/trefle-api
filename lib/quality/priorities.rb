module Quality
  # The work queue: most requested species with the poorest data.
  # Demand signal: species_trends, falling back to wiki_score, then gbif_score.
  class Priorities

    Row = Struct.new(:id, :slug, :scientific_name, :completion_ratio, :demand, :signal, keyword_init: true)

    def self.fetch(limit: 100, max_completion: 50)
      queries(limit, max_completion).each do |signal, sql|
        rows = ActiveRecord::Base.connection.select_all(sql).to_a
        next if rows.empty?

        return rows.map {|r| Row.new(signal: signal, **r.symbolize_keys) }
      end

      []
    end

    def self.queries(limit, max_completion)
      [
        [:species_trends, <<~SQL],
          SELECT s.id, s.slug, s.scientific_name, s.completion_ratio, t.demand
          FROM species s
          INNER JOIN (
            SELECT species_id, SUM(score) AS demand
            FROM species_trends
            GROUP BY species_id
          ) t ON t.species_id = s.id
          WHERE COALESCE(s.completion_ratio, 0) < #{max_completion.to_i}
          ORDER BY t.demand DESC, COALESCE(s.completion_ratio, 0) ASC
          LIMIT #{limit.to_i}
        SQL
        [:wiki_score, <<~SQL],
          SELECT id, slug, scientific_name, completion_ratio, wiki_score AS demand
          FROM species WHERE wiki_score > 0 AND COALESCE(completion_ratio, 0) < #{max_completion.to_i}
          ORDER BY wiki_score DESC, COALESCE(completion_ratio, 0) ASC LIMIT #{limit.to_i}
        SQL
        [:gbif_score, <<~SQL]
          SELECT id, slug, scientific_name, completion_ratio, gbif_score AS demand
          FROM species WHERE gbif_score > 0 AND COALESCE(completion_ratio, 0) < #{max_completion.to_i}
          ORDER BY gbif_score DESC, COALESCE(completion_ratio, 0) ASC LIMIT #{limit.to_i}
        SQL
      ]
    end

    private_class_method :queries

  end
end
