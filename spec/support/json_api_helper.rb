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

  def self.resource_schema(schema_name, links: nil, meta: nil)
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
