require 'rails_helper'

RSpec.describe SitemapWorker, type: :worker do
  it 'points the sitemap generator at the production host and pings search engines' do
    allow(SitemapGenerator::Sitemap).to receive(:ping_search_engines)

    described_class.new.perform

    expect(SitemapGenerator::Sitemap.default_host).to eq('https://trefle.io')
    expect(SitemapGenerator::Sitemap).to have_received(:ping_search_engines)
  end
end
