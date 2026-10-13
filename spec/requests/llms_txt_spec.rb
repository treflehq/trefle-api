require 'rails_helper'

# public/llms.txt is the orientation file for programs; its links are
# hand-written, so check the ones that point back into this app.
RSpec.describe 'public/llms.txt' do
  let(:text) { Rails.public_path.join('llms.txt').read }
  let(:about) { Rails.root.join('app/views/home/about.html.erb').read }

  it 'only links to sections the about page has' do
    anchors = text.scan(%r{https://trefle\.io/about#([\w-]+)}).flatten.uniq

    expect(anchors).not_to be_empty
    anchors.each do |anchor|
      expect(about).to include(%(id="#{anchor}")), "about##{anchor} has no matching section"
    end
  end

  it 'only names API paths the router knows' do
    paths = text.scan(%r{^\s+GET (/[\w/{}]+)}).flatten.uniq

    expect(paths).to include('/species/{id}/synonyms')
    paths.each do |path|
      concrete = "/api/v1#{path.gsub(/\{\w+\}/, 'x')}"
      recognized = begin
        Rails.application.routes.recognize_path(concrete, method: :get)
      rescue ActionController::RoutingError
        nil
      end
      expect(recognized).not_to be_nil, "#{path} is not routed"
    end
  end
end
