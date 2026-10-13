# Aggregates for the new home page (#303/#305): taxonomic rank breakdown,
# field completeness shares, and recent correction activity.
#
# Every one of these is a full-table aggregate over Species/RecordCorrection,
# so each value is cached independently for at least an hour rather than
# keyed to a counter (the pattern the old home page counters use). That's
# deliberate: a deploy invalidates the page fragment cache, and a short or
# counter-keyed cache would mean every request recomputing every aggregate at
# once right after rollout.
class HomeStatsPresenter
  include RecordCorrectionHelper

  CACHE_EXPIRY = 1.hour

  # One label per value of the `rank` enum. `subvar` is the subvariety
  # (ICN rank below the variety), not a cultivar: cultivars are named under
  # the ICNCP and the enum has no rank for them.
  RANK_LABELS = {
    'species' => 'Species',
    'var' => 'Varieties',
    'ssp' => 'Subspecies',
    'hybrid' => 'Hybrids',
    'form' => 'Forms',
    'subvar' => 'Subvarieties'
  }.freeze

  GROWTH_CONDITIONS_SQL = <<~SQL.squish
    light IS NOT NULL OR atmospheric_humidity IS NOT NULL OR ground_humidity IS NOT NULL OR
    soil_texture IS NOT NULL OR soil_salinity IS NOT NULL OR soil_nutriments IS NOT NULL OR
    ph_minimum IS NOT NULL OR ph_maximum IS NOT NULL OR
    minimum_temperature_deg_c IS NOT NULL OR maximum_temperature_deg_c IS NOT NULL OR
    minimum_precipitation_mm IS NOT NULL OR maximum_precipitation_mm IS NOT NULL OR
    hardiness_zone IS NOT NULL
  SQL

  # `edible` is excluded on purpose: it's a derived column (traits.yml has it
  # under category: derived, outside the counted completion categories) that
  # a Species callback always sets to true/false from vegetable/edible_part,
  # so it is never actually null and would make every species "complete".
  EDIBILITY_AND_USES_SQL = <<~SQL.squish
    vegetable IS NOT NULL OR edible_part != 0 OR toxicity IS NOT NULL
  SQL

  # Order matters here: it's the display order on the home page.
  FIELD_COMPLETENESS_GROUPS = {
    'Bibliography & author' => ->(scope) { scope.where.not(bibliography: [nil, '']).where.not(author: [nil, '']) },
    'Images' => ->(scope) { scope.where('images_count > 0') },
    'Distribution' => ->(scope) { scope.where(id: SpeciesDistribution.select(:species_id).distinct) },
    'Common names' => ->(scope) { scope.where(id: CommonName.where(record_type: 'Species').select(:record_id).distinct) },
    'Growth conditions' => ->(scope) { scope.where(GROWTH_CONDITIONS_SQL) },
    'Edibility & uses' => ->(scope) { scope.where(EDIBILITY_AND_USES_SQL) }
  }.freeze

  CORRECTION_ACTIVITY_WINDOW = 30.days
  LATEST_REVIEWED_LIMIT = 5

  # Counts of species per taxonomic rank, in display order, plus the total
  # synonym count (shown as a separate footnote on the home page).
  def records_by_rank
    Rails.cache.fetch('home_stats/records_by_rank', expires_in: CACHE_EXPIRY) do
      counts = Species.group(:rank).count
      RANK_LABELS.each_with_object({}) {|(rank, label), acc| acc[label] = counts[rank] || 0 }
    end
  end

  def synonyms_count
    Rails.cache.fetch('home_stats/synonyms_count', expires_in: CACHE_EXPIRY) { Synonym.count }
  end

  # % of species (out of all Species rows, matching the existing counters'
  # convention) with each group of fields filled in.
  def field_completeness_shares
    Rails.cache.fetch('home_stats/field_completeness_shares', expires_in: CACHE_EXPIRY) do
      total = Species.count
      FIELD_COMPLETENESS_GROUPS.each_with_object({}) do |(label, scope_builder), acc|
        acc[label] = share(scope_builder.call(Species), total)
      end
    end
  end

  # Changes whenever a correction is filed or decided. The correction
  # figures are cached under it, so a decision shows on the home page at
  # once instead of an hour (or a day of page cache) later.
  def corrections_stamp
    @corrections_stamp ||= RecordCorrection.maximum(:updated_at)&.to_i
  end

  # 30-day correction activity: corrections reviewed (accepted or rejected),
  # submitted and accepted, distinct contributors, and the fields the accepted
  # corrections changed. Decisions are dated by `decided_at`, not
  # `updated_at`, which later edits of the row move.
  def correction_activity
    Rails.cache.fetch(['home_stats/correction_activity', corrections_stamp], expires_in: CACHE_EXPIRY) do
      submitted_scope = RecordCorrection.where(created_at: CORRECTION_ACTIVITY_WINDOW.ago..)
      reviewed_scope = RecordCorrection.where.not(change_status: :pending).where(decided_at: CORRECTION_ACTIVITY_WINDOW.ago..)
      accepted_scope = reviewed_scope.accepted_change_status

      {
        reviewed: reviewed_scope.count,
        submitted: submitted_scope.count,
        accepted: accepted_scope.count,
        fields_completed: fields_completed(accepted_scope),
        contributors: submitted_scope.distinct.count(:user_id)
      }
    end
  end

  # The 5 most recently reviewed (accepted or rejected) corrections, newest
  # first, as plain hashes — no AR objects escape the cache.
  def latest_reviewed_corrections
    Rails.cache.fetch(['home_stats/latest_reviewed_corrections', corrections_stamp], expires_in: CACHE_EXPIRY) do
      RecordCorrection
        .where.not(change_status: :pending)
        .where(record_type: 'Species')
        .includes(:user, :record)
        .order(Arel.sql('decided_at DESC NULLS LAST'), updated_at: :desc)
        .limit(LATEST_REVIEWED_LIMIT)
        .map {|correction| reviewed_entry(correction) }
    end
  end

  private

  def share(scope, total)
    return 0 if total.zero?

    ((scope.count * 100.0) / total).round(1)
  end

  # The fields an accepted correction set: the keys of its correction, the
  # name excepted (it identifies the record and is sent with every
  # correction). A deletion sets none. Over a 30-day window this is a few
  # hundred small JSON documents at most.
  def fields_completed(accepted_scope)
    accepted_scope.where.not(correction_json: [nil, '']).pluck(:correction_json).sum do |json|
      (JSON.parse(json).keys - ['scientific_name']).size
    rescue JSON::ParserError
      0
    end
  end

  def reviewed_entry(correction)
    species = correction.record

    {
      species_name: species&.scientific_name,
      species_slug: species&.slug,
      status: correction.change_status,
      description: title_for_correction(correction),
      contributor: contributor_name(correction.user),
      reviewed_at: correction.decided_at || correction.updated_at
    }
  end

  def contributor_name(user)
    return 'Anonymous' if user.nil?

    user.name.presence || user.github_username.presence || user.email
  end

end
