
# OpenAPI generation (dry run of the rswag request specs, writes public/swagger/v1/swagger.yaml --
# the file GET /api/v1/openapi.json serves). Commit the result: CI fails when it is behind.
bundle exec rake rswag:specs:swaggerize

# Markdown docs
rake doc:generate_spec
mv SPECS.md ../trefle-docs/docs/advanced/plants-fields.md
cp ./public/swagger/v1/swagger.yaml ../trefle-docs/static/swagger.yaml