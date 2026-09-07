require 'rails_helper'

RSpec.feature 'Account page', type: :feature do

  scenario 'User can see the account links' do
    user = FactoryBot.create(:user)
    login_as(user, scope: :user)

    visit '/'
    # The redesigned header/footer (#304) show a capitalized "Account" link
    # for signed-in visitors rather than the old home page's "My account" CTA.
    expect(page).to have_text('Account')
  end

  scenario 'User can go to his profile' do
    user = FactoryBot.create(:user)
    login_as(user, scope: :user)

    visit '/profile'
    expect(page).to have_text('Your account')
    expect(page).to have_text('Access token')
    expect(page).to have_selector("input[value='#{user.token}']")
    expect(page).to have_text('Account informations')
  end

end
