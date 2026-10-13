class SpeciesLightSerializer < BaseSerializer

  attributes :id, :common_name, :slug, :scientific_name,
             :year, :bibliography, :author, :status,
             :rank, :family_common_name, :family,
             :genus_id, :genus,
             :links, :synonyms_count, :image_url,
             :completion_ratio, :complete_data

  def image_url
    object.main_image_url
  end

  # List payloads carry the count of the synonyms attached to this record
  # (a counter column, no extra query) and a link to the paginated list;
  # the names themselves are no longer embedded (a species can have a
  # thousand of them).

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
      genus: url_helpers.api_v1_genus_path(object&.genus&.slug || 'unknown'),
      synonyms: url_helpers.api_v1_species_synonyms_path(object)
    }
  end

end
