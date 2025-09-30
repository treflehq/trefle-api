# == Schema Information
#
# Table name: foreign_sources_plants
#
#  id                :bigint           not null, primary key
#  fid               :string(255)
#  inserted_at       :datetime         not null
#  last_update       :datetime
#  record_type       :string
#  created_at        :datetime
#  updated_at        :datetime         not null
#  foreign_source_id :bigint
#  record_id         :bigint
#  species_id        :bigint
#
# Indexes
#
#  foreign_sources_plants_foreign_source_id_index                 (foreign_source_id)
#  foreign_sources_plants_species_id_fid_foreign_source_id_index  (species_id,fid,foreign_source_id) UNIQUE
#  index_foreign_sources_plants_on_fid                            (fid)
#  index_foreign_sources_plants_on_record_type_and_record_id      (record_type,record_id)
#
# Foreign Keys
#
#  foreign_sources_plants_foreign_source_id_fkey  (foreign_source_id => foreign_sources.id)
#  foreign_sources_plants_species_id_fkey         (species_id => species.id)
#
class ForeignSourcesPlant < ApplicationRecord
  belongs_to :species, optional: true
  belongs_to :record, polymorphic: true
  belongs_to :foreign_source

  counter_culture %i[species plant], column_name: 'sources_count'
  counter_culture [:species], column_name: 'sources_count'

  before_validation :set_record_from_species
  before_validation :set_species_from_record

  def set_record_from_species
    return unless species_id

    self.record = Species.find(species_id)
  end

  def set_species_from_record
    return unless record_type && record_type == 'Species'

    self.species_id = record_id
  end

  def full_url
    # usda", "tropicos", "tela-botanica", "powo
    case foreign_source.slug
    when 'usda'
      "https://plants.usda.gov/core/profile?symbol=#{fid}"
    when 'tropicos'
      "http://legacy.tropicos.org/Name/#{fid}"
    when 'tela-botanica' # rubocop:todo Lint/EmptyWhen
    when 'plantnet'
      "https://identify.plantnet.org/species/the-plant-list/#{fid}"
    when 'gbif'
      "https://www.gbif.org/species/#{fid}"
    when 'powo'
      "http://powo.science.kew.org/taxon/#{fid}"
    when 'wikipedia_en'
      "https://en.wikipedia.org/wiki/#{fid}"
    end
  end

  def citation
    # usda", "tropicos", "tela-botanica", "powo
    case foreign_source.slug
    when 'usda'
      "https://plants.sc.egov.usda.gov/core/profile?symbol=#{fid}"
    when 'tropicos'
      'Tropicos, botanical information system at the Missouri Botanical Garden - www.tropicos.org'
    when 'tela-botanica' # rubocop:todo Lint/EmptyWhen
    when 'powo'
      "POWO (2019). Plants of the World Online. Facilitated by the Royal Botanic Gardens, Kew. Published on the Internet; http://www.plantsoftheworldonline.org/ Retrieved #{last_update&.to_date}"
    end
  end
end
