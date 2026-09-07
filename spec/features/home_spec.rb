require 'rails_helper'

RSpec.feature 'Home page', type: :feature do

  scenario 'User visits the home page' do
    visit '/'
    expect(page).to have_text('Explore the plants')
    expect(page).to have_text('Read the documentation')
    expect(page).to have_text('Sign in')
    expect(page).to have_text('Documentation')
  end

  scenario 'User visits the about page' do
    visit '/about'
    expect(page).to have_text('About Trefle')
    expect(page).to have_text('Trefle is free for all, and always will be.')
    expect(page).to have_text('Contact')
    expect(page).to have_text('hello@trefle.io')
    expect(page).to have_text('Sign in')
    expect(page).to have_text('Documentation')
  end
end
