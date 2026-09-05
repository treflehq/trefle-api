# Backfills synonyms.slug (same derivation as the before_save callback).
# Replayable: only touches rows where the slug is missing or stale.
class Migrators::SynonymSlugsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: true, backtrace: true

  def perform(*_args)
    updated = 0

    Synonym.where(slug: nil).find_in_batches(batch_size: 1000) do |batch|
      pairs = batch.filter_map do |synonym|
        slug = synonym.name.to_s.parameterize
        [synonym.id, slug] if slug.present?
      end
      next if pairs.empty?

      values = pairs.map do |id, slug|
        "(#{id}, #{Synonym.connection.quote(slug)})"
      end.join(', ')

      Synonym.connection.execute(<<~SQL.squish)
        UPDATE synonyms SET slug = v.slug
        FROM (VALUES #{values}) AS v(id, slug)
        WHERE synonyms.id = v.id
      SQL
      updated += pairs.size
    end

    Rails.logger.info("[SynonymSlugsWorker] backfilled #{updated} slugs")
    updated
  end
end
