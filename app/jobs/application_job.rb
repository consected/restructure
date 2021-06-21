# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  attr_accessor :provider_job

  def log(txt)
    puts txt unless Rails.env.test?
  end

  #
  # Hook to catch failures
  # Send at most one email (to admin email) per hour from this server, relying
  # on memcached to skip the mail call if one has already been sent
  # @param [<Type>] _job - ignored
  def failure(_job)
    Rails.cache.fetch('delayed_job-failure-notification', expires_in: 1.hour) do
      options = {
        to: Settings::AdminEmail,
        from: Settings::NotificationsFromEmail || Settings::AdminEmail,
        body: "A failure occurred running a delayed_job on server #{EnvironmentName}.",
        content_type: 'text/plain',
        subject: 'delayed_job failure'
      }
      mail(options)
      DateTime.now
    end
  rescue StandardError => e
    log "Failure in the ApplicationJob.failure: #{e}"
  end
end
