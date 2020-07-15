class MigrateNewSpeciesColumns < ActiveRecord::Migration[6.0]
  # rubocop:todo Metrics/MethodLength
  def self.up # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength # rubocop:todo Metrics/MethodLength
    add_column :species, :s_status, :integer
    add_column :species, :s_toxicity, :integer
    add_column :species, :s_foliage_texture, :integer

    add_column :species, :inflorescence, :string
    add_column :species, :sexuality, :string
    add_column :species, :maturation_order, :string
    add_column :species, :pollinisation, :string
    add_column :species, :fruit_shape, :string
    add_column :species, :dissemination, :string

    add_column :species, :ligneous_type, :integer

    add_column :species, :f_flower_color, :integer, null: false, default: 0, limit: 8
    add_column :species, :f_fruit_color, :integer, null: false, default: 0, limit: 8
    add_column :species, :light, :integer
    add_column :species, :atmospheric_humidity, :integer
    add_column :species, :ground_humidity, :integer

    # q = <<-SQL
    #   UPDATE species
    # SQL

    # ActiveRecord::Base.connection.execute(q)
    Species.where(status: 'Accepted').update_all(s_status: :accepted)
    Species.where(status: 'Unknown').update_all(s_status: :unknown)

    Species.where(toxicity: 'None').update_all(s_toxicity: :none)
    Species.where(toxicity: 'Slight').update_all(s_toxicity: :low)
    Species.where(toxicity: 'Moderate').update_all(s_toxicity: :medium)
    Species.where(toxicity: 'Severe').update_all(s_toxicity: :high)

    Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)

    Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)

    Species.group(:flower_color).count.keys.compact.map do |str_color|
      puts "Migrating #{str_color} flower colors"
      Species.where(flower_color: str_color).update_all(f_flower_color: Species.f_flower_colors.maps[str_color.underscore.to_sym])
    end

    Species.group(:fruit_color).count.keys.compact.map do |str_color|
      puts "Migrating #{str_color} fruit colors"
      Species.where(fruit_color: str_color).update_all(f_fruit_color: Species.f_fruit_colors.maps[str_color.underscore.to_sym])
    end

    Species.where(foliage_texture: 'Fine').update_all(s_foliage_texture: :fine)
    Species.where(foliage_texture: 'Medium').update_all(s_foliage_texture: :medium)
    Species.where(foliage_texture: 'Coarse').update_all(s_foliage_texture: :coarse)
  end
  # rubocop:enable Metrics/MethodLength

  def self.down
    remove_column :species, :s_status
    remove_column :species, :s_toxicity
    remove_column :species, :s_foliage_texture

    remove_column :species, :inflorescence
    remove_column :species, :sexuality
    remove_column :species, :maturation_order
    remove_column :species, :pollinisation
    remove_column :species, :fruit_shape
    remove_column :species, :dissemination

    remove_column :species, :ligneous_type

    remove_column :species, :f_flower_color
    remove_column :species, :f_fruit_color
    remove_column :species, :light
    remove_column :species, :atmospheric_humidity
    remove_column :species, :ground_humidity
  end
end
