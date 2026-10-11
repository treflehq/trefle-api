require 'rails_helper'

# Devise authenticates in a filter it prepends (require_no_authentication),
# and on authentication it deletes the CSRF token from the session
# (clean_up_csrf_token_on_authentication). If CSRF is verified after that, a
# correct password always fails verification, and with: :null_session drops
# the session: the user lands on the home page signed out, with no message.
# The test environment disables forgery protection, which is why no spec saw
# it; this one turns it on.
RSpec.describe 'Signing in with forgery protection on', type: :request do
  let(:password) { SecureRandom.hex(12) }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def authenticity_token
    get '/users/sign_in'
    response.body[/name="authenticity_token" value="([^"]+)"/, 1]
  end

  it 'keeps the session of a user who signs in with the right password' do
    user.update_columns(terms_accepted_at: Time.current, terms_version: TERMS_VERSION)
    token = authenticity_token

    post '/users/sign_in', params: { authenticity_token: token, user: { email: user.email, password: password } }
    follow_redirect!

    expect(controller.current_user).to eq(user)
  end
end
