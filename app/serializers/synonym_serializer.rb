# == Schema Information
#
# Table name: synonyms
#
#  id          :bigint           not null, primary key
#  author      :string
#  name        :string
#  notes       :text
#  record_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint           not null
#
# Indexes
#
#  index_synonyms_on_name                       (name)
#  index_synonyms_on_record_type_and_record_id  (record_type,record_id)
#

class SynonymSerializer < BaseSerializer

  attributes :id, :name, :author # , :synonym_of

  # link(:self) {|o| url_helpers.api_v1_genus_path(o) }

  has_many :foreign_sources_plants, serializer: ForeignSourcesPlantSerializer, name: :sources

  def link_for(object)
    case object.record_type
    when 'Species'
      url_helpers.api_v1_species_path(object.record_id)
    when 'Genus'
      url_helpers.api_v1_genus_path(object.record_id)
    end
  end

  def synonym_of
    {
      link: link_for(object),
      type: object.record_type,
      id: object.record_id
    }
  end
end
