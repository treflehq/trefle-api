#!/usr/bin/env bash
# Repo verification, run by the stop-verify hook before a feature session may
# end: rubocop + the full RSpec suite (same gates as CI).
# Worktree-aware: untracked local files (.env*.local, the compiled JS bundle)
# only exist in the main checkout, so borrow or rebuild them first.
set -euo pipefail
cd "$(dirname "$0")/.."

main_checkout=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
for f in .env.local .env.test.local .env.development.local; do
  if [ ! -f "$f" ] && [ -f "$main_checkout/$f" ]; then
    cp "$main_checkout/$f" "$f"
  fi
done

bundle check >/dev/null 2>&1 || bundle install --quiet

if [ ! -f app/assets/builds/application.js ]; then
  npx -y yarn@1.22.22 install --frozen-lockfile --silent
  npx -y yarn@1.22.22 build >/dev/null
fi

bundle exec rubocop --format quiet
RAILS_ENV=test bin/rails db:test:prepare
bundle exec rspec --format progress
