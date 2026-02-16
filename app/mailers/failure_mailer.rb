# frozen_string_literal: true

#
# Simple mailer for job failures (and other admin notifications)
class FailureMailer < ActionMailer::Base
  default to: Settings::FailureNotificationsToEmail,
          from: Settings::NotificationsFromEmail || Settings::AdminEmail,
          content_type: 'text/plain'

  #
  # Defines the mail to be sent as a notification of a background job failure
  # @param [ApplicationJob] job -
  #                       typically do something like job.to_yaml to avoid calling with types that
  #                       a background job can't handle
  def notify_job_failure(job_id, job_yaml, exception = nil)
    view_job = "View job at: #{Settings::BaseUrl}/admin/job_reviews?filter[job_id]=#{job_id}" if job_id
    body = <<~END_TEXT
      A failure occurred running a delayed_job on server #{Settings::EnvironmentName}.

      #{exception}

      #{view_job}

      #{job_yaml}"
    END_TEXT

    if Settings::FailureNotificationsToEmail.blank?
      Rails.logger.warn "Settings::FailureNotificationsToEmail is blank - no notify_job_failure will be sent.\n#{body}"
      return
    end

    Rails.logger.info "Sending job failure message:\n#{body}"
    options = {
      body:,
      subject: 'delayed_job failure'
    }
    mail(options)
  end
end
