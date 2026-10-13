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

  # Infraspecific ranks first: "Rosa × odorata var. erubescens" is a variety
  # that happens to carry the hybrid sign, not a hybrid (#414). Nil when no
  # rank fits, so the caller can leave the record's rank alone and let
  # validation say so.
  def self.rank_for(name)
    %i[ssp var form subvar hybrid species].find {|rank| name.to_s.match?(SCIENTIFIC_NAME_VALIDATION_REGEX[rank]) }&.to_s
  end

  # Two connecting terms in one string: "Dryas octopetala subsp. octopetala
  # var. kamtschatica" is the full classification of a variety, the way USDA
  # PLANTS prints it, not a name. A name has one infraspecific rank (ICN Art.
  # 24.1); the rest is classification (TAXONOMY.md, "One infraspecific rank
  # per name"). Refused with its own message, whatever the record's rank.
  CONNECTING_TERM = '(?:ssp|subsp|var|subvar|form|fo?)\\.'.freeze
  # The hybrid sign may stand apart before the genus or an epithet.
  TWO_RANKS = /\A(?:× )?\S+ (?:× )?\S+ #{CONNECTING_TERM} (?:× )?\S+ #{CONNECTING_TERM} (?:× )?\S+\z/

  def validate_each(record, attribute, value)
    if value.to_s.match?(TWO_RANKS)
      record.errors.add(attribute, "'#{value}' carries two infraspecific ranks; a name has one (ICN Art. 24.1), the rest is classification")
      return
    end

    reg = SCIENTIFIC_NAME_VALIDATION_REGEX[record.rank.to_sym]
    record.errors.add(attribute, "structure of '#{value}' seems invalid for #{record.rank} rank") if (value =~ reg).nil?
  end
end
