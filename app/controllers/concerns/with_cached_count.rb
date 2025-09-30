module WithCachedCount
  extend ActiveSupport::Concern

  def pagy_get_vars(collection, vars)
    vars[:count] ||= cache_count(collection)
    vars[:page]  ||= params[vars[:page_param] || Pagy::DEFAULT[:page_param]]
    vars
  end

  # add Rails.cache wrapper around the count call
  def cache_count(collection)
    cache_key = "pagy-#{collection.model.name}:#{collection.to_sql}"
    puts "Caching count for #{collection.model.name}"
    Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
      puts "Count cached for #{collection.model.name} !"
      collection.count(:all)
    end
  end
end
