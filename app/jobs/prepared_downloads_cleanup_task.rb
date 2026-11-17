# frozen_string_literal: true

class PreparedDownloadsCleanupTask
  include Delayed::RecurringJob

  run_every 1.hour

  queue 'recurring-tasks'

  def perform
    NfsStore::PreparedDownload.new.cleanup!
  end
end
