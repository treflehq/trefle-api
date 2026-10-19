# == Schema Information
#
# Table name: synonyms
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  author      :string
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  slug        :string
#
# Indexes
#
#  index_synonyms_on_name                       (name)
#  index_synonyms_on_record_type_and_record_id  (record_type,record_id)
#  index_synonyms_on_slug                       (slug)
#

class Synonym < ApplicationRecord
  belongs_to :record, polymorphic: true
  has_many :record_corrections, as: :record, dependent: :destroy
  has_many :foreign_sources_plants, as: :record, dependent: :destroy
  has_many :foreign_sources, through: :foreign_sources_plants

  validates :name, presence: true, uniqueness: { scope: %i[record_type] }

  auto_strip_attributes :author, :name, :notes

  # Same derivation as a species slug, so the name keeps resolving through
  # /species/:slug after a synonym-species record is merged away.
  before_save :derive_slug

  # The proc receives the counted record (this synonym), not its parent:
  # decide on record_type. Testing `model.respond_to?(:synonyms_count)` here
  # was always false, so the live counter never moved and the column only
  # ever got filled by counter_culture_fix_counts.
  counter_culture :record,
                  column_name: proc {|synonym| synonym.record_type == 'Species' ? 'synonyms_count' : nil },
                  column_names: {
                    ['synonyms.record_type = ?', 'Species'] => 'synonyms_count'
                  }

  validate :have_different_name

  def have_different_name
    errors.add(:name, 'Must be different than the record') if record.respond_to?(:scientific_name) && (record.scientific_name == name)
  end

  def derive_slug
    self.slug = name.to_s.parameterize if slug.blank? || will_save_change_to_name?
  end

end
