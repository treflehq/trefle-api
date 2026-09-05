require 'rails_helper'

RSpec.feature 'Species page', type: :feature do
  scenario 'Species with a photo gets a large lead image instead of a small thumbnail' do
    species = create(:species, main_image_url: 'https://bs.plantnet.org/image/o/abc123.jpg')

    visit "/explore/species/#{species.slug}"

    expect(page).to have_text(species.scientific_name)
    photo = page.find('.species-lead-photo', visible: :all)
    expect(photo[:src]).to eq('https://bs.plantnet.org/image/m/abc123.jpg')
  end

  scenario 'Species without a photo falls back to the tinted placeholder' do
    species = create(:species, main_image_url: nil)

    visit "/explore/species/#{species.slug}"

    expect(page).to have_css('.species-lead-photo.species-lead-photo--empty')
    expect(page).to have_no_css('img.species-lead-photo')
  end
end
