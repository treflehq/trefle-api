RSpec::Matchers.define :match_response_schema do |schema|
  match do |response|
    options = {
      # strict: true
    }
    options[:list] = true if response.is_a?(Array)
    JSON::Validator.validate!(Schemas::V1::SCHEMAS[schema.to_sym], response, options)
  end
end
