class SpeciesLightSerializer < BaseSerializer

  attributes :id, :common_name, :slug, :scientific_name,
             :year, :bibliography, :author, :status,
             :rank, :family_common_name, :family,
             :genus_id, :genus,
             :links, :synonyms, :image_url

  def image_url
    object.main_image_url
  end

  def synonyms
    object.synonyms.pluck(:name)
  end

  # def common_names
  #   object.common_names.pluck(:name)
  # end

  def genus
    object.genus_name || object&.genus&.name
  end

  def family
    object.family_name || object&.genus&.family&.name
  end

  def links
    {
      self: url_helpers.api_v1_species_path(object),
      plant: url_helpers.api_v1_plant_path(object&.plant&.slug || 'unknown'),
      genus: url_helpers.api_v1_genus_path(object&.genus&.slug || 'unknown')
    }
  end

end
