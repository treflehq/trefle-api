# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://trefle.io'

SitemapGenerator::Sitemap.create(compress: false) do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  add about_path, priority: 0.7, changefreq: 'weekly'
  add terms_path, priority: 0.7, changefreq: 'weekly'
  add new_user_session_path, priority: 0.3, changefreq: 'weekly'
  add new_user_registration_path, priority: 0.3, changefreq: 'weekly'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
