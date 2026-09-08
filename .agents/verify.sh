#!/usr/bin/env bash
# Repo verification, run by the stop-verify hook before a feature session may
# end: rubocop + the full RSpec suite (same gates as CI).
# Worktree-aware: untracked local files (.env*.local, the compiled JS bundle)
# only exist in the main checkout, so borrow or rebuild them first.
set -euo pipefail
cd "$(dirname "$0")/.."

main_checkout=$(cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")" && pwd -P)
for f in .env.local .env.test.local .env.development.local; do
  if [ ! -f "$f" ] && [ -f "$main_checkout/$f" ]; then
    cp "$main_checkout/$f" "$f"
  fi
done

# Several sessions run this script at once, from different worktrees, against one
# local Postgres. `db:test:prepare` drops and recreates the test database, so two
# runs finishing together race on it and one dies with
#   PG::UniqueViolation ... duplicate key value violates unique constraint
#   "pg_database_datname_index" ... Key (datname)=(trefle_test) already exists.
# Give each worktree its own database (see config/database.yml). The main checkout
# and CI set nothing and keep plain `trefle_test`, so nothing else changes.
if [ "$(pwd -P)" != "$main_checkout" ]; then
  slug=$(printf '%s' "$(basename "$(pwd -P)")" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | cut -c1-45)
  export PG_TEST_DATABASE="trefle_test_${slug}"
  echo "verify: using test database ${PG_TEST_DATABASE}"
fi

bundle check >/dev/null 2>&1 || bundle install --quiet

if [ ! -f app/assets/builds/application.js ]; then
  npx -y yarn@1.22.22 install --frozen-lockfile --silent
  npx -y yarn@1.22.22 build >/dev/null
fi

bundle exec rubocop --format quiet
RAILS_ENV=test bin/rails db:test:prepare
bundle exec rspec --format progress
