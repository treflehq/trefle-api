class ScientificNameStructureValidator < ActiveModel::EachValidator

  # The genus part. An intergeneric hybrid (nothogenus) is written with the
  # multiplication sign and a space before the genus, "× Agropogon lutosus"
  # (ICN H.3); "×Agropogon" without the space is tolerated as before.
  GENUS = '(?:× ?)?[A-Z][a-z-]+'.freeze
  # An epithet under an infraspecific rank. A nothospecies keeps its sign
  # there too: "Rosa × odorata var. erubescens".
  EPITHET = '(?:× ?)?[a-z][a-z-]+'.freeze

  SCIENTIFIC_NAME_VALIDATION_REGEX = {
    # Besides a binomial, WCVP accepts a few apomictic aggregates at species
    # rank under their section name: the common dandelion is "Taraxacum sect.
    # Taraxacum" (Taraxacum officinale is its synonym). Epithets can be a
    # single letter ("Lepanthes o").
    species: /\A(#{GENUS}) ([a-z][a-z-]*|sect\. [A-Z][a-z-]+)\z/,
    var: /\A(#{GENUS}) (#{EPITHET}) (var\.) (#{EPITHET})\z/,
    ssp: /\A(#{GENUS}) (#{EPITHET}) (ssp|subsp)\. (#{EPITHET})\z/,
    form: /\A(#{GENUS}) (#{EPITHET}) (form|fo?)\. (#{EPITHET})\z/,
    hybrid: /\A(#{GENUS}) × ([a-z-]+)(\s.*)?\z/,
    subvar: /\A(#{GENUS}) (#{EPITHET}) (subvar\.) (#{EPITHET})\z/
  }.freeze

  def validate_each(record, attribute, value)
    reg = SCIENTIFIC_NAME_VALIDATION_REGEX[record.rank.to_sym]
    record.errors.add(attribute, "structure of '#{value}' seems invalid for #{record.rank} rank") if (value =~ reg).nil?
  end
end
