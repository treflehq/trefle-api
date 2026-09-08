require 'rails_helper'

# The families show-page fix (see families_spec.rb) surfaced a related bug on
# every other slugged taxonomy resource in the back-office: their controllers
# looked records up with `Model.find(params[:id])`, but every link generated
# from a view (index's "Show"/"Edit", show's "Edit") passes the FriendlyId
# slug, not the numeric id, via `to_param`. `Model.find(<slug>)` raises
# ActiveRecord::RecordNotFound, so the page was unreachable by clicking
# through the UI even though it happened to work when the numeric id was
# typed into the URL directly. Fixed by switching those controllers to
# `Model.friendly.find`, matching the pattern already used by
# genuses/plants/species.
RSpec.describe 'Management show pages reachable via their own slug', type: :request do
  before { login_as create(:admin), scope: :user }

  # Records come from the seeded taxonomy tree (db/botanic_seeds.rb) rather
  # than FactoryBot: those tables are seeded with hardcoded ids and no
  # sequence bump (a pre-existing gap, same as the foreign_sources_id_seq
  # setval already worked around in rails_helper.rb), so freshly-factoried
  # rows can collide with them on id. Reading an existing seeded row sidesteps
  # that without touching unrelated infrastructure.
  {
    division: -> { Division.first },
    division_class: -> { DivisionClass.first },
    division_order: -> { DivisionOrder.first },
    foreign_source: -> { ForeignSource.first },
    kingdom: -> { Kingdom.first },
    subkingdom: -> { Subkingdom.first }
  }.each do |resource, record|
    it "renders /management/#{resource.to_s.pluralize}/:slug" do
      path_helper = "management_#{resource}_path"
      get send(path_helper, record.call)
      expect(response).to have_http_status(:ok)
    end
  end
end
