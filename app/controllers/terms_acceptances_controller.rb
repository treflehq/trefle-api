# frozen_string_literal: true

# One-time prompt shown to a signed-in web visitor whose terms acceptance is
# missing or stale (see RequiresTermsAcceptance and TERMS_VERSION in
# config/initializers/terms.rb). Covers both pre-existing users (accepted an
# older version, or never recorded one) and brand new GitHub OAuth sign-ups,
# which have no interactive step to show a checkbox during the callback
# itself. Never runs against the JSON API: Api::ApiController is a separate
# ActionController::API stack that never includes RequiresTermsAcceptance, so
# tokens keep working regardless of whether this prompt has been accepted
# (#320).
class TermsAcceptancesController < ApplicationController
  before_action :authenticate_user!

  def new
    @return_to = safe_return_to(params[:return_to])
  end

  def create
    if truthy_param?(params.dig(:user, :accepts_terms))
      current_user.accepts_terms = true
      current_user.save!
      redirect_to safe_return_to(params[:return_to]), notice: 'Thanks -- your acceptance of the Terms of Use has been recorded.'
    else
      @return_to = safe_return_to(params[:return_to])
      flash.now[:alert] = 'You must accept the Terms of Use to keep using the Trefle website.'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def truthy_param?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  # `return_to` comes from an untrusted query/hidden-field param -- only
  # honor same-site paths so it can't be turned into an open redirect.
  def safe_return_to(path)
    return root_path if path.blank? || !path.start_with?('/') || path.start_with?('//')

    path
  end
end
