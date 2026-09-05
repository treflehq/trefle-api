# Keeps the serialization cache warm for the records people actually request.
#
# Replaces the standalone "heater" service, which walked every collection in an
# infinite loop with a half-second pause. At 489k species that is 68 days for a
# single pass, so it never completed one — and it needed its own image, its own
# deployment and an unlimited API token baked into the manifest.
#
# This runs in the app instead. Two consequences worth stating:
#
#   * Requests are issued in-process through the Rack stack, so they go through
#     the real controllers and populate exactly the cache keys a real request
#     would look up. Reproducing those keys by hand would drift the first time
#     a controller changed what it caches.
#   * Work is ordered by demand rather than by table order, so the budget goes
#     to records that are actually looked up.
class CacheWarmerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low, retry: false, backtrace: true

  DEFAULT_BATCH = 200
  COLLECTIONS = %w[
    /api/v1/kingdoms
    /api/v1/subkingdoms
    /api/v1/families
    /api/v1/distributions
    /api/v1/genus
    /api/v1/plants
    /api/v1/species
  ].freeze

  def perform(batch_size = DEFAULT_BATCH)
    token = warming_token
    unless token
      Rails.logger.error('[CacheWarmer] no unlimited token available, skipping')
      return false
    end

    warmed = 0
    warmed += warm_collections(token)
    warmed += warm_records(token, batch_size)

    Rails.logger.info("[CacheWarmer] warmed #{warmed} responses")
    warmed
  end

  private

  # rack-attack safelists tokens starting with 'unl-', so warming does not eat
  # into anyone's quota and cannot throttle itself. Read from the database
  # rather than the environment: the old service carried its token in a
  # committed manifest, which is how it ended up needing rotation.
  def warming_token
    User.where(admin: true).find_each do |user|
      return user.token if user.token&.starts_with?('unl-')
    end
    nil
  end

  def warm_collections(token)
    COLLECTIONS.count {|path| get(path, token) }
  end

  # Most-requested first. species_trends is the real signal; gbif_score stands
  # in until it is populated, the same fallback the work queue uses.
  def warm_records(token, batch_size)
    species = Species.order(gbif_score: :desc).limit(batch_size).pluck(:slug)
    plants = Plant.order(main_species_gbif_score: :desc).limit(batch_size / 2).pluck(:slug)

    species.count {|slug| get("/api/v1/species/#{slug}", token) } +
      plants.count {|slug| get("/api/v1/plants/#{slug}", token) }
  end

  def get(path, token)
    env = Rack::MockRequest.env_for(
      "http://localhost#{path}?token=#{token}",
      'HTTP_HOST' => 'localhost'
    )
    status, = Rails.application.call(env)
    return true if status == 200

    Rails.logger.warn("[CacheWarmer] #{path} returned #{status}")
    false
  rescue StandardError => e
    # One bad record must not stop the sweep.
    Rails.logger.warn("[CacheWarmer] #{path} raised #{e.class}: #{e.message}")
    false
  end
end
