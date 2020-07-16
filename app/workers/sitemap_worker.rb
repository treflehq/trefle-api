class SitemapWorker
  include Sidekiq::Worker

  def perform(*args)
    SitemapGenerator::Sitemap.default_host = 'https://trefle.io'
    SitemapGenerator::Sitemap.ping_search_engines
  end
end
