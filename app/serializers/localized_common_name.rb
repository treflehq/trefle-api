# `common_name` in the language of the request's `lang` parameter, and
# `common_name_lang`, the language it is actually in (see
# CommonNameLocalization). Without `lang` the serializer context carries no
# localizer: `common_name` is the record's own (English) column and
# `common_name_lang` is left out of the payload.
#
# Panko turns an attribute into a method field only when the method is
# defined in the serializer class itself (Panko::Serializer.method_added),
# so the serializers define `common_name` and `common_name_lang` and call
# #localized_common_name.
module LocalizedCommonName
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Applied to the serializer the response is built with. A serializer
    # nested through has_one/has_many has its filters fixed when the parent
    # class is loaded (no context then): it localizes `common_name` but
    # never shows `common_name_lang`.
    def filters_for(context, _scope)
      context.is_a?(Hash) && context[:common_names] ? {} : { except: [:common_name_lang] }
    end
  end

  protected

  # [name, lang]; species_id: the species whose names are looked up (the
  # main species, for a plant).
  def localized_common_name(species_id = object.id)
    localizer = context.is_a?(Hash) ? context[:common_names] : nil
    return [object.common_name, nil] unless localizer

    localizer.localize(species_id, fallback: object.common_name)
  end
end
