require 'rspec/expectations'

module JsonApiHelper
  def self.array_schema(schema_name, links: nil, meta: nil)
    {
      type: :object,
      properties: {
        data: {
          type: :array,
          items: Schemas::Helpers.schema_href(schema: schema_name)
        },
        links: links,
        meta: meta
      }.compact
    }
  end

  # Every detail payload's meta also carries dataset_version
  # (CollectionRenderers#render_serialized_resource).
  def self.resource_schema(schema_name, links: nil, meta: nil)
    if meta && meta[:properties]
      meta = meta.merge(
        properties: meta[:properties].merge(dataset_version: Schemas::Helpers::DATASET_VERSION),
        required: [*meta[:required], 'dataset_version']
      )
    end
    {
      type: :object,
      properties: {
        data: Schemas::Helpers.schema_href(schema: schema_name),
        links: links,
        meta: meta
      }.compact
    }
  end

  def self.save_example(example, response)
    example.metadata[:response][:examples] ||= {}
    example.metadata[:response][:examples][example.metadata[:description].parameterize] = {}
    example.metadata[:response][:examples][example.metadata[:description].parameterize][:value] = JSON.parse(response.body, symbolize_names: true)
  end
end
