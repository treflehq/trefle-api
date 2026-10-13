class BaseSerializer < Panko::Serializer

  # include FastJsonapi::ObjectSerializer
  # cache_options enabled: true, cache_length: 1.week
  attributes :id

  delegate :url_helpers, to: :'Rails.application.routes'

  # The top-level keys the serializer renders, mapped to the name Panko's
  # `only:` option filters them by: an association renamed with `name:`
  # (`has_many :species_species, name: :species`) is filtered on its method
  # name. See SparseFieldsets.
  def self.field_filters
    descriptor = _descriptor
    fields = (descriptor.attributes + descriptor.method_fields).to_h {|field| [field.name.to_s, field.name.to_sym] }
    (descriptor.has_one_associations + descriptor.has_many_associations).each do |association|
      fields[association.name_str] = association.name_sym
    end
    fields
  end

  def self.field_names
    field_filters.keys
  end

  protected

  def render_flag(flag)
    object.send(flag).to_a.empty? ? nil : object.send(flag).to_a
  end
end
