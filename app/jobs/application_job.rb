# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  attr_accessor :provider_job

  def log(txt)
    puts txt unless Rails.env.test?
  end

  around_perform do |job, block|
    Rails.logger.info "Run job - #{job}"
    Application.refresh_dynamic_defs
    block.call
  rescue StandardError, FsException, FphsException, RuntimeError, IOError => e
    begin
      msg = "Job failed - #{e} : #{job}"
      puts msg unless Rails.env.test?
      Rails.logger.warn msg
      Rails.logger.warn e.short_string_backtrace
      ApplicationJob.notify_failure job, e
    rescue StandardError, FsException, FphsException, RuntimeError, IOError => e2
      msg = "Job failed in rescue: #{e2} : #{job}"
      puts msg
      Rails.logger.error msg
      Rails.logger.error e.backtrace.join("\n")
      ApplicationJob.notify_failure job, e
    end
    raise
  end

  #
  # Hook to catch failures
  # Send at most one email (to admin email) per hour from this server, relying
  # on memcached to skip the mail call if one has already been sent
  # @param [ActiveJob::Base] job
  def self.notify_failure(job, exception = nil)
    Rails.cache.fetch('delayed_job-failure-notification', expires_in: 1.hour) do
      job_id = job.id if job.respond_to? :id
      job_id = job.job_id if job_id.nil? && job.respond_to?(:job_id)

      nj = FailureMailer.notify_job_failure(
        job_id,
        job.inspect.gsub(' @', "\n@"),
        exception.to_s
      )

      if Rails.env.test?
        nj.deliver_now
      else
        nj.deliver_later
      end
      DateTime.now.to_s
    end
  rescue Exception => e
    puts e
    puts e.backtrace.join("\n")
    Rails.logger.error "Failed to send notify_failure: #{e}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
