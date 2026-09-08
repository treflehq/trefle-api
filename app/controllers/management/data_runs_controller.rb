# Journal of the data operations run against this database (DataRun):
# imports, purges, migrations — including one-off runs from outside the
# cluster. Read-only: the rows are written by the runs themselves.
class Management::DataRunsController < Management::ManagementController

  def index
    @runs = DataRun.recent.limit(200)
  end

  def show
    @run = DataRun.find(params[:id])
  end

end
