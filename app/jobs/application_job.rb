# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  attr_accessor :provider_job

  def log(txt)
    puts txt unless Rails.env.test?
  end

  around_perform do |job, block|
    Rails.logger.info "Run job - #{job}"
    block.call
  rescue StandardError, FsException, FphsException => e
    begin
      msg = "Job failed - #{e} : #{job}"
      puts msg unless Rails.env.test?
      Rails.logger.warn msg
      Rails.logger.warn e.backtrace.join("\n")
      ApplicationJob.notify_failure job
    rescue StandardError, FsException, FphsException => e2
      msg = "Job failed in rescue: #{e2} : #{job}"
      puts msg
      Rails.logger.error msg
      Rails.logger.error e.backtrace.join("\n")
      ApplicationJob.notify_failure job
    end
    raise
  end

  #
  # Hook to catch failures
  # Send at most one email (to admin email) per hour from this server, relying
  # on memcached to skip the mail call if one has already been sent
  # @param [ActiveJob::Base] job
  def self.notify_failure(job)
    Rails.cache.fetch('delayed_job-failure-notification', expires_in: 1.hour) do
      options = {
        to: Settings::AdminEmail,
        from: Settings::NotificationsFromEmail || Settings::AdminEmail,
        body: "A failure occurred running a delayed_job on server #{EnvironmentName}.\n#{job}",
        content_type: 'text/plain',
        subject: 'delayed_job failure'
      }
      mail(options)
      DateTime.now
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send notify_failure: #{e}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
