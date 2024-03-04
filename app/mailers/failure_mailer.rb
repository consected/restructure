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
  def notify_job_failure(job)
    view_job = "View job at: #{Settings::BaseUrl}/admin/job_reviews?filter[id]=#{job.id}" if job.respond_to? :id
    body = <<~END_TEXT
      A failure occurred running a delayed_job on server #{Settings::EnvironmentName}.

      #{view_job}

      #{job.to_yaml}"
    END_TEXT

    options = {
      body: body,
      subject: 'delayed_job failure'
    }
    mail(options)
  end
end
