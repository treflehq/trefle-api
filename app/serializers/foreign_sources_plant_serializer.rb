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

class ForeignSourcesPlantSerializer < BaseSerializer

  attributes :id, :name, :url, :citation, :last_update

  def id
    object.fid
  end

  def name
    object&.foreign_source&.name
  end

  def url
    object&.full_url
  end

  def citation
    object&.citation
  end

end
