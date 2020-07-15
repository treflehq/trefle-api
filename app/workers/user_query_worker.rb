# Will update the queries counters
class UserQueryWorker
  include Sidekiq::Worker

  def perform
    UserQuery.persist_all_to_database!
  end
end
