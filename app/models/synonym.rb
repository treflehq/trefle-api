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
class Synonym < ApplicationRecord
  belongs_to :record, polymorphic: true
  has_many :record_corrections, as: :record, dependent: :destroy
  has_many :foreign_sources_plants, as: :record, dependent: :destroy
  has_many :foreign_sources, through: :foreign_sources_plants

  validates :name, presence: true, uniqueness: { scope: %i[record_type] }

  auto_strip_attributes :author, :name, :notes

  counter_culture :record,
                  column_name: proc {|model| model.respond_to?(:synonyms_count) ? 'synonyms_count' : nil },
                  column_names: {
                    ['synonyms.record_type = ?', 'Species'] => 'synonyms_count'
                  }

  validate :have_different_name

  def have_different_name # rubocop:todo Naming/PredicateName
    if record.respond_to?(:scientific_name) # rubocop:todo Style/GuardClause
      errors.add(:name, 'Must be different than the record') if record.scientific_name == name
    end
  end

  def self.auto_migrate # rubocop:todo Metrics/PerceivedComplexity
    Species.where(status: 'Synonym').find_in_batches.with_index.each do |sps, i|
      puts "Batching species group #{i}"
      sps.each do |sp|
        if sp.synonym_of_id == sp.id || sp.main_species_id == sp.id
          sp.update(
            status: 'Unknown',
            synonym_of_id: sp.synonym_of_id == sp.id ? nil : sp.synonym_of_id,
            main_species_id: sp.main_species_id == sp.id ? nil : sp.main_species_id
          )
        else
          good_sp = sp.synonym_of || sp.main_species
          if good_sp
            synonym = Synonym.where(name: sp.scientific_name, record: good_sp).first_or_create!(
              author: sp.author
            )
            sp.foreign_sources_plants.map do |fsp|
              fsp.update!(record: synonym, species_id: nil)
            end
            puts "FS: #{sp.foreign_sources_plants.count}"
            puts "Images: #{sp.species_images.count}"
          end
          sp.reload.destroy

        end
      end
    end
  end

end
