class SpeciesLightSerializer < BaseSerializer

  include LocalizedCommonName

  attributes :id, :common_name, :common_name_lang, :slug, :scientific_name,
             :year, :bibliography, :author, :status,
             :rank, :family_common_name, :family,
             :genus_id, :genus,
             :links, :synonyms_count, :image_url, :main_image,
             :completion_ratio, :complete_data

  def common_name
    localized_common_name.first
  end

  def common_name_lang
    localized_common_name.last
  end

  def image_url
    object.main_image_url
  end

  def main_image
    serialize_main_image(object.main_image_url, species_id: object.id)
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
