require 'rails_helper'

# The back-office new/edit pages were generated as top-level scaffolds and then
# moved under /management: their forms and redirects still called the
# top-level helpers (family_path, families_url…), which do not exist, so every
# new/edit page answered 500 and every save ended on an error page.
RSpec.describe 'Management new/edit pages', type: :request do
  before { login_as create(:admin), scope: :user }

  # Seeded rows rather than factories, see friendly_id_show_pages_spec.rb.
  {
    division: -> { Division.first },
    division_class: -> { DivisionClass.first },
    division_order: -> { DivisionOrder.first },
    family: -> { Family.first },
    foreign_source: -> { ForeignSource.first },
    genuse: -> { Genus.first },
    kingdom: -> { Kingdom.first },
    subkingdom: -> { Subkingdom.first },
    plant: -> { Species.friendly.find('abies-alba').plant }
  }.each do |resource, record|
    it "renders the new and edit pages of #{resource.to_s.pluralize}" do
      get send("new_management_#{resource}_path")
      expect(response).to have_http_status(:ok)

      get send("edit_management_#{resource}_path", record.call)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{send("management_#{resource}_path", record.call)}"))
    end
  end

  it 'renders the new species page' do
    get new_management_species_path
    expect(response).to have_http_status(:ok)
  end

  it 'redirects a genus update to its management page' do
    genus = Genus.first

    patch management_genuse_path(genus), params: { genuse: { name: genus.name } }

    expect(response).to redirect_to(management_genuse_path(genus))
  end

  it 'redirects a family update to its management page' do
    family = Family.first

    patch management_family_path(family), params: { family: { name: family.name } }

    expect(response).to redirect_to(management_family_path(family))
  end

  it 'lists the images of a species reached by its slug' do
    species = Species.friendly.find('abies-alba')

    get management_species_species_images_path(species.slug)

    expect(response).to have_http_status(:ok)
  end
end
