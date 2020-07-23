# == Schema Information
#
# Table name: zones
#
#  id            :bigint           not null, primary key
#  feature       :string
#  name          :string           not null
#  slug          :string
#  species_count :integer          default(0), not null
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
  friendly_id :name, use: :slugged

  def self.fix_global_counts
    Zone.all.each do |z|
      z.update_columns(species_count: z.all_species.count, updated_at: Time.zone.now)
    end
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
    Species.joins(:species_distributions).where(species_distributions: {zone_id: self_and_descendents.pluck(:id)})
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
