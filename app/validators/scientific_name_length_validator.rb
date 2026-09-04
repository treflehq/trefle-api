class ScientificNameLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    chunks = value.split(' ')

    record.errors.add(attribute, "'#{value}' is invalid, must be at least binomial") if chunks.count < 2

    return unless chunks.count < 3 && !record.species_rank? && !record.hybrid_rank?

    record.errors.add(attribute, "'#{value}' is invalid for the #{record.rank} rank, must be at least trinomial")
  end
end
