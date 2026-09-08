require 'socket'

# One row per data operation run against this database: imports, purges,
# migrations, crawls. The journal lives in the database on purpose — pod
# logs rotate, and one-off runs (a laptop port-forwarded onto production)
# leave no trace anywhere else.
#
#   DataRun.track!(runnable: self.class.name, kind: 'import',
#                  arguments: { paths: paths }, dry_run: dry_run) do |run|
#     stats = do_the_work
#     stats # a Hash return value becomes the stored report
#   end
#
# Every tracked run measures the dataset's key counters before and after,
# so the impact is recorded as observed deltas rather than claimed ones.
# Failures are recorded (status, error, partial impact) and re-raised.
class DataRun < ApplicationRecord

  enum :status, { running: 0, completed: 1, failed: 2 }, suffix: true

  validates :runnable, :kind, presence: true

  scope :recent, -> { order(started_at: :desc) }

  # Cheap enough to run twice per tracked run, wide enough that a run
  # touching anything structural shows up.
  IMPACT_COUNTERS = {
    'species' => -> { Species.count },
    'plants' => -> { Plant.count },
    'synonyms' => -> { Synonym.count },
    'species_facts' => -> { SpeciesFact.count },
    'active_facts' => -> { SpeciesFact.active_status.count },
    'common_names' => -> { CommonName.count },
    'species_images' => -> { SpeciesImage.count },
    'species_distributions' => -> { SpeciesDistribution.count },
    'foreign_sources_plants' => -> { ForeignSourcesPlant.count }
  }.freeze

  def self.track!(runnable:, kind:, arguments: {}, dry_run: false)
    run = create!(
      runnable: runnable, kind: kind, arguments: arguments, dry_run: dry_run,
      started_at: Time.zone.now, host: Socket.gethostname,
      revision: ENV.fetch('APP_REVISION', nil)
    )
    before = capture_counters

    begin
      result = yield run
      run.update!(
        status: :completed, finished_at: Time.zone.now,
        report: result.is_a?(Hash) ? result : run.report,
        impact: impact_between(before, capture_counters)
      )
      result
    rescue Exception => e # rubocop:disable Lint/RescueException
      # Even a SystemStackError deserves a journal entry (one killed a purge
      # run once); the failure is recorded with its partial impact, then
      # re-raised untouched.
      run.update!(
        status: :failed, finished_at: Time.zone.now,
        error: "#{e.class}: #{e.message.to_s[0, 500]}",
        impact: impact_between(before, capture_counters)
      )
      raise
    end
  end

  def self.capture_counters
    IMPACT_COUNTERS.transform_values(&:call)
  end

  def self.impact_between(before, after)
    before.to_h do |name, was|
      now = after[name]
      [name, { 'before' => was, 'after' => now, 'delta' => now - was }]
    end
  end

  def duration
    return nil unless finished_at && started_at

    finished_at - started_at
  end

  # The deltas worth showing on a list row.
  def moved_counters
    impact.select {|_name, values| values['delta']&.nonzero? }
  end

end
