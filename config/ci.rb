# Run using bin/ci
#
# Mirrors the three jobs of .github/workflows/ci.yml (RuboCop, Brakeman, RSpec).
# Requires PostgreSQL and Redis running, like `bundle exec rspec`.

CI.run do
  step 'Style: Ruby', 'bin/rubocop'

  step 'Security: Brakeman code analysis', 'bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error'

  step 'Tests: prepare database', 'env RAILS_ENV=test bin/rails db:test:prepare'
  step 'Tests: RSpec', 'bundle exec rspec'
end
