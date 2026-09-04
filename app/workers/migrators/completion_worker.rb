# Recomputes completion_ratio / complete_data for every species after a
# change of the completion definition (config/traits.yml). Replayable.
class Migrators::CompletionWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  def perform(*_args)
    done = 0
    # rubocop:disable Rails/SkipsModelValidations -- deliberate: mass recompute without touching updated_at
    Species.find_each(batch_size: 1000) do |species|
      ratio = species.current_completion_percentage
      species.update_columns(completion_ratio: ratio, complete_data: ratio > 50)
      done += 1
    end

    Plant.includes(:main_species).find_each(batch_size: 1000) do |plant|
      ratio = plant.current_completion_percentage
      plant.update_columns(completion_ratio: ratio, complete_data: ratio > 25)
    end
    # rubocop:enable Rails/SkipsModelValidations

    Rails.logger.info("[Migrators::CompletionWorker] recomputed #{done} species")
    true
  end
end
