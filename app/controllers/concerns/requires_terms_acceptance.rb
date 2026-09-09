# frozen_string_literal: true

# Shared by every controller that renders the public web app (see
# ApplicationController and Explore::ExploreController): a signed-in visitor
# whose terms_accepted_at/terms_version is missing or stale gets sent to
# accept the current version (TermsAcceptancesController) before doing
# anything else -- browsing explore/ pages, submitting a record correction,
# managing their profile, etc.
#
# Deliberately NOT included in Management::ManagementController (the admin
# back office -- gating it risks locking out an admin over a UX detail) or
# anywhere in the JSON API (Api::ApiController is a separate
# ActionController::API stack that never sees this concern; the
# `controller_path.start_with?('api/')` guard below also covers the one
# pre-existing quirk where Api::V1::HomeController inherits
# ApplicationController directly instead of Api::ApiController). API access
# is never gated on this (#320).
module RequiresTermsAcceptance
  extend ActiveSupport::Concern

  included do
    before_action :require_terms_acceptance!
  end

  private

  def require_terms_acceptance!
    return unless user_signed_in?
    return if devise_controller?
    return if controller_path == 'terms_acceptances'
    # The terms themselves must stay readable, or the gate asks people to accept
    # a document they cannot open: the acceptance form links to `terms_path`
    # (shared/_terms_checkbox_field), and without this the link bounces straight
    # back to the form. `/terms` is home#licence, so `controller_path` is 'home'
    # and the exemption above does not cover it.
    return if request.path == terms_path
    return if controller_path.start_with?('api/')
    return if current_user.terms_up_to_date?

    redirect_to new_terms_acceptance_path(return_to: request.fullpath)
  end
end
