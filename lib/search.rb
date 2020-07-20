module Search
  POOL = ConnectionPool.new(size: 2) { MeiliSearch::Client.new(ENV['MEILISEARCH_URL'], ENV['MEILISEARCH_KEY']) }

  def self.instance
    POOL
  end

  def self.search_species(q, opts = {})
    POOL.with do |conn|
      conn.index('species').search(q, { limit: 20 }.merge(opts))
    end
  end
end
