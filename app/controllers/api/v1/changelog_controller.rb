# The public history of the dataset versions (DatasetVersion): one entry per
# data run that may have written to the data, newest first. Public like the
# root, so that a citation's version can be checked without an account.
#
# Only the fields safe to publish leave the journal: the run's kind, status,
# dates and the observed counter deltas. The runnable class, arguments,
# report, host, revision and error stay in the back office (Management::
# DataRunsController): they name private tooling, local paths and machines.
class Api::V1::ChangelogController < ApplicationController

  LIMIT = 100

  def index
    entries = Rails.cache.fetch(['changelog/v1', DatasetVersion.current_version], expires_in: DatasetVersion::CACHE_TTL) do
      DatasetVersion.history(limit: LIMIT).map {|run, version| entry(run, version) }
    end

    response.headers['X-Trefle-Data-Version'] = DatasetVersion.current_version if DatasetVersion.current_version
    render json: {
      data: entries,
      meta: { total: entries.size, dataset_version: DatasetVersion.current_version }
    }
  end

  private

  def entry(run, version)
    {
      version: version.version,
      kind: run.kind,
      status: run.status,
      started_at: run.started_at,
      finished_at: run.finished_at,
      changes: run.moved_counters.transform_values {|values| values['delta'] }
    }
  end

end
