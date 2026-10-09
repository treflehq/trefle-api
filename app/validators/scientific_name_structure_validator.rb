class ScientificNameStructureValidator < ActiveModel::EachValidator

  SCIENTIFIC_NAME_VALIDATION_REGEX = {
    # Besides a binomial, WCVP accepts a few apomictic aggregates at species
    # rank under their section name: the common dandelion is "Taraxacum sect.
    # Taraxacum" (Taraxacum officinale is its synonym). Epithets can be a
    # single letter ("Lepanthes o").
    species: /\A(×?[A-Z][a-z-]+) ([a-z][a-z-]*|sect\. [A-Z][a-z-]+)\z/,
    var: /\A(×?[A-Z][a-z-]+) ([a-z×][a-z-]+) (var\.) ([a-z×][a-z-]+)\z/,
    ssp: /\A(×?[A-Z][a-z-]+) ([a-z×][a-z-]+) (ssp|subsp)\. ([a-z×][a-z-]+)\z/,
    form: /\A(×?[A-Z][a-z-]+) ([a-z×][a-z-]+) (form|fo?)\. ([a-z×][a-z-]+)\z/,
    hybrid: /\A(×?[A-Z][a-z-]+) × ([a-z-]+)(\s.*)?\z/,
    subvar: /\A(×?[A-Z][a-z-]+) ([a-z×][a-z-]+) (subvar\.) ([a-z×][a-z-]+)\z/
  }.freeze

  def validate_each(record, attribute, value)
    reg = SCIENTIFIC_NAME_VALIDATION_REGEX[record.rank.to_sym]
    record.errors.add(attribute, "structure of '#{value}' seems invalid for #{record.rank} rank") if (value =~ reg).nil?
  end
end
