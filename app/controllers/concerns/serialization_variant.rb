# The query parameters that shape a serialized payload (`lang`, `fields`)
# without changing the record: CollectionRenderers puts them in the cache
# key and the ETag (#serialization_variant), and hands them to the
# serializers as a Panko context (#serializer_options_with_context).
#
# A controller adds a parameter by overriding #serialization_variant_parts
# and #serialization_context, calling super, so that several parameters
# compose.
module SerializationVariant
  extend ActiveSupport::Concern

  # The parameters as one stable string (`lang=fr`), or nil for the default
  # payload, whose key stays what it was. The values must already be
  # normalized, so that two spellings of one request share an entry.
  def serialization_variant
    serialization_variant_parts.compact_blank.map {|name, value| "#{name}=#{value}" }.join('&').presence
  end

  def serialization_variant_parts
    {}
  end

  # What the serializers read through `context[:key]`.
  def serialization_context
    {}
  end

  # serializer_options with the request's serialization context merged in.
  # Always a new hash: Panko merges its filters into the options it is given.
  def serializer_options_with_context(serializer_options)
    context = serialization_context
    return serializer_options.dup if context.empty?

    serializer_options.merge(context: (serializer_options[:context] || {}).merge(context))
  end
end
