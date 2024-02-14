# frozen_string_literal: true

#
# Simple mailer for job failures (and other admin notifications)
class FailureMailer < ActionMailer::Base
  default to: Settings::FailureNotificationsToEmail,
          from: Settings::NotificationsFromEmail || Settings::AdminEmail,
          content_type: 'text/plain'

  #
  # Defines the mail to be sent as a notification of a background job failure
  # @param [String] job - typically do something like job.inspect to avoid calling with types that
  #                       a background job can't handle
  def notify_job_failure(job)
    options = {
      body: "A failure occurred running a delayed_job on server #{Settings::EnvironmentName}.\n#{job&.to_yaml}",
      subject: 'delayed_job failure'
    }
    mail(options)
  end
end
