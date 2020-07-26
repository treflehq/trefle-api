class PlantLightSerializer < BaseSerializer

  attributes :id, :common_name, :slug, :scientific_name,
             :year, :bibliography, :author, #:status,
             :family_common_name, :genus_id,
             :main_species_id, :vegetable,
             :observations,
             :links, :image_url

  def image_url
    object.main_image_url
  end

  # def year
  #   object.main_species&.year
  # end

  # def bibliography
  #   object.main_species&.bibliography
  # end

  # def author
  #   object.main_species&.author
  # end

  # def family_common_name
  #   object.main_species&.family_common_name
  # end

  # def genus_id
  #   object.main_species&.genus_id
  # end

  # def observations
  #   object.main_species&.observations
  # end

  # def vegetable
  #   object.main_species&.vegetable
  # end

  def links
    {
      self: url_helpers.api_v1_plant_path(object),
      species: url_helpers.api_v1_plant_species_index_path(object),
      genus: url_helpers.api_v1_genus_path(object&.genus&.slug || 'unknown')
    }
  end
end
