require 'rails_helper'

RSpec.feature 'Home page', type: :feature do

  scenario 'User visits the home page' do
    visit '/'
    expect(page).to have_text('Get started')
    expect(page).to have_text('Browse the docs')
    expect(page).to have_text('Sign in')
    expect(page).to have_text('Documentation')
  end

  scenario 'User visits the about page' do
    visit '/about'
    expect(page).to have_text('We deliver all plants informations')
    expect(page).to have_text('Contact us')
    expect(page).to have_text('Sign in')
    expect(page).to have_text('Documentation')
  end
end
