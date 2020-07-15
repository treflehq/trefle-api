
# Swagger generation
rspec --pattern spec/requests/\*\*/\*_spec.rb --format Rswag::Specs::SwaggerFormatter  --order defined
mv ./swagger/v1/swagger.yaml ./public/swagger/v1/swagger.yaml

# Markdown docs
rake doc:generate_spec
mv SPECS.md ../trefle-docs/docs/advanced/plants-fields.md
cp ./public/swagger/v1/swagger.yaml ../trefle-docs/static/swagger.yaml