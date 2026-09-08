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
    expect(page).to have_text('We deliver all plants informations')
    expect(page).to have_text('Contact us')
    expect(page).to have_text('Sign in')
    expect(page).to have_text('Documentation')
  end

  scenario 'User visits the citation page' do
    visit '/citation'
    expect(page).to have_text('Citation')
    expect(page).to have_text('Trefle: a global plants API')
    expect(page).to have_text('BibTeX')
    expect(page).to have_text('DOI pending')
  end

  scenario 'User follows the citation link from the about page' do
    visit '/about'
    click_link 'citation formats and DOI'
    expect(page).to have_current_path('/citation')
  end
end
