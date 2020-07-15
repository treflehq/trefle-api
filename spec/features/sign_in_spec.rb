require 'rails_helper'

RSpec.feature 'Sign in/up page', type: :feature do

  scenario 'User can create an account' do
    visit '/users/sign_up'

    fill_in 'user_email',    with: 'test@lala.co'
    fill_in 'user_password', with: 'asamplepassword'
    fill_in 'user_password_confirmation', with: 'asamplepassword'
    click_button 'Sign up'

    expect(page).to have_content 'A message with a confirmation link'
    expect(User.find_by_email('test@lala.co')).to be

  end

  scenario 'User can sign in' do
    user = FactoryBot.create(:user, password: 'anotherpassword')

    visit '/users/sign_in'

    fill_in 'user_email',    with: user.email
    fill_in 'user_password', with: 'anotherpassword'
    click_button 'Log in'

    expect(page).to have_text('account')
    expect(page).to have_content 'Signed in successfully'
  end

end
