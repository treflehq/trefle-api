# == Schema Information
#
# Table name: common_names
#
#  id          :integer          not null, primary key
#  record_type :string           not null
#  record_id   :integer          not null
#  name        :string
#  lang        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_common_names_on_record_type_and_record_id  (record_type,record_id)
#

class CommonName < ApplicationRecord
  belongs_to :record, polymorphic: true

  validates :name, uniqueness: { scope: %i[lang record_id record_type] }

  LANGUAGES_CACHE_KEY = 'common_names/languages'.freeze
  LANGUAGES_TTL = 1.hour

  # The names of a species in a language (an ISO 639-1 code), whichever tag
  # the source stored it under (`fr`, `fra`...; see Iso639).
  scope :in_language, ->(lang) { where(record_type: 'Species', lang: tags_for(lang)) }

  # The names equal to one of `names`, trimmed, ignoring case and accents
  # (`tomate`, `Tomate` and ` TOMATE` match each other, `mais` matches `maïs`).
  scope :named, lambda {|names|
    where(
      'lower(unaccent(btrim(common_names.name))) IN (SELECT lower(unaccent(btrim(v))) FROM unnest(ARRAY[?]::text[]) AS v)',
      [*names].map(&:to_s)
    )
  }

  # The languages the species common names exist in, by ISO 639-1 code, with
  # the stored tags behind each: { 'fr' => ['fr', 'fra'], ... }. A tag without
  # a two-letter code (blank, `lub`...) is left out. English is always there:
  # a species carries its English name in its own `common_name` column.
  # The 334 distinct tags take one scan of the table, hence the cache.
  def self.languages
    Rails.cache.fetch(LANGUAGES_CACHE_KEY, expires_in: LANGUAGES_TTL) do
      tags = where(record_type: 'Species').distinct.pluck(:lang).compact
      languages = tags.group_by {|tag| Iso639.alpha2(tag) }.except(nil)
      languages['en'] ||= ['en']
      languages.transform_values(&:sort).sort.to_h
    end
  end

  def self.tags_for(lang)
    languages.fetch(lang.to_s, [])
  end
end
