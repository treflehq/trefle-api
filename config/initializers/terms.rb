# frozen_string_literal: true

# Version tag for the Terms of Use (see /terms). Bump this string whenever
# the terms change materially -- every user, new or already registered, is
# then asked to accept the new version once, on their next visit to the web
# app (see ApplicationController#require_terms_acceptance!). API access is
# never gated on this: tokens keep working regardless (#320).
TERMS_VERSION = '2026-09-07'
