# == Schema Information
#
# Table name: zones
#
#  id            :bigint           not null, primary key
#  feature       :string
#  name          :string           not null
#  slug          :string
#  species_count :integer          default(0), not null
#  species_count_cumulative :integer default(0), not null
#  tdwg_code     :string
#  tdwg_level    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :integer
#
class Zone < ApplicationRecord

  has_many :species_distributions, dependent: :destroy
  has_many :species, through: :species_distributions
  has_many :all_species, through: :all_species_distributions

  has_many :children, class_name: 'Zone', foreign_key: 'parent_id', dependent: :destroy
  belongs_to :parent, optional: true, class_name: 'Zone'

  scope :root_level, -> { where(parent_id: nil) }

  include Filterable
  include Sortable
  include Rangeable

  include Scopes::Zones

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  def slug_candidates
    [
      :tdwg_code,
      %i[tdwg_code name]
    ]
  end

  def self.fix_global_counts
    Zone.all.each do |z|
      z.update_columns(species_count: z.all_species.count, updated_at: Time.zone.now)
    end
  end

  # Resolves a zone from a path parameter: the slug (TDWG code, `fra`) or the
  # numeric id as before, then the exact zone name, case- and
  # accent-insensitive (`France`, `reunion`). Clients rarely know the TDWG
  # code of a country; they know its name.
  #
  # A name shared by several zones (WGSRPD has "Mongolia" at level 2 and 3)
  # resolves to the level 3 zone, the "botanical country" a bare country name
  # denotes. Any other ambiguity, like no match at all, is a 404 whose message
  # points to `?q=`.
  def self.resolve!(param)
    friendly.find(param.to_s.downcase)
  rescue ActiveRecord::RecordNotFound
    candidates = named(param).to_a
    zone = candidates.one? ? candidates.first : botanical_country_among(candidates)
    return zone if zone

    raise ActiveRecord::RecordNotFound, not_found_message(param, candidates)
  end

  def self.botanical_country_among(candidates)
    countries = candidates.select {|z| z.tdwg_level == 3 }
    countries.first if countries.one?
  end

  def self.not_found_message(param, candidates)
    search_hint = "search zones by name with /api/v1/distributions?q=#{ERB::Util.url_encode(param.to_s)}"
    if candidates.any?
      list = candidates.map {|z| "#{z.slug} (TDWG level #{z.tdwg_level})" }.join(', ')
      "#{param.to_s.inspect} matches #{candidates.size} zones: #{list}. Use the slug, or #{search_hint}"
    else
      "can't find zone #{param.to_s.inspect}: use its slug (the TDWG code, e.g. \"fra\" for France), or #{search_hint}"
    end
  end

  # Distinct species recorded in the zone or in any zone below it, for every
  # zone in one statement: the recursive CTE pairs each zone with itself and
  # all its descendants, the join counts the distinct species over that set.
  # Only rows whose value changed are written, with updated_at bumped so the
  # serializer cache (keyed on cache_version) drops the stale payload.
  def self.fix_cumulative_counts
    connection.execute(<<~SQL.squish).cmd_tuples
      WITH RECURSIVE tree(root_id, zone_id, path) AS (
          SELECT id, id, ARRAY[id] FROM zones
        UNION ALL
          SELECT tree.root_id, zones.id, tree.path || zones.id
          FROM tree
          JOIN zones ON zones.parent_id = tree.zone_id
          WHERE NOT zones.id = ANY(tree.path)
      ),
      counts AS (
        SELECT tree.root_id AS zone_id, COUNT(DISTINCT species_distributions.species_id) AS species_count
        FROM tree
        JOIN species_distributions ON species_distributions.zone_id = tree.zone_id
        GROUP BY tree.root_id
      )
      UPDATE zones
      SET species_count_cumulative = COALESCE(counts.species_count, 0),
          updated_at = CURRENT_TIMESTAMP
      FROM zones AS target
      LEFT JOIN counts ON counts.zone_id = target.id
      WHERE zones.id = target.id
        AND zones.species_count_cumulative <> COALESCE(counts.species_count, 0)
    SQL
  end

  def touch_parents
    parents.map(&:touch)
  end

  def to_desc
    [parent&.to_desc, name].compact.join(' > ')
  end

  def to_hierarchy
    [*parent&.to_hierarchy, self].compact
  end

  def parent_ids
    [*parent&.parent_ids, parent_id].compact
  end

  def parents
    [*parent&.parents, parent].compact
  end

  def all_species_distributions
    SpeciesDistribution.where(zone_id: self_and_descendents.pluck(:id))
  end

  def all_species
    Species.joins(:species_distributions).where(species_distributions: { zone_id: self_and_descendents.pluck(:id) })
  end

  def descendents
    self_and_descendents - [self]
  end

  def self_and_descendents
    self.class.tree_for(self)
  end

  def descendent_zones
    subtree = self.class.tree_sql_for(self)
    Zone.where("parent_id IN (#{subtree})")
  end

  def direct_descendent_zones
    Zone.where(parent_id: id)
  end

  def brother_zones
    Zone.where(parent_id: parent_id)
  end

  def self.tree_for(instance)
    where("#{table_name}.id IN (#{tree_sql_for(instance)})").order("#{table_name}.id")
  end

  def self.zone_ids_for_slug(slug)
    where("#{table_name}.id IN (#{ids_for_slug_sql_for(slug)})").order("#{table_name}.id")
  end

  def self.tree_sql_for(instance)
    _tree_sql = <<-SQL
      WITH RECURSIVE search_tree(id, path) AS (
          SELECT id, ARRAY[id]
          FROM #{table_name}
          WHERE id = #{instance.id}
        UNION ALL
          SELECT #{table_name}.id, path || #{table_name}.id
          FROM search_tree
          JOIN #{table_name} ON #{table_name}.parent_id = search_tree.id
          WHERE NOT #{table_name}.id = ANY(path)
      )
      SELECT id FROM search_tree ORDER BY path
    SQL
  end

  def self.ids_for_slug_sql_for(slug)
    tree_sql = <<-SQL
      WITH RECURSIVE search_tree(id, path) AS (
          SELECT id, ARRAY[id]
          FROM #{table_name}
          WHERE slug LIKE ?
        UNION ALL
          SELECT #{table_name}.id, path || #{table_name}.id
          FROM search_tree
          JOIN #{table_name} ON #{table_name}.parent_id = search_tree.id
          WHERE NOT #{table_name}.id = ANY(path)
      )
      SELECT id FROM search_tree ORDER BY path
    SQL
    ActiveRecord::Base.send(:sanitize_sql_array, [tree_sql, slug])
  end

end
