# frozen_string_literal: true

#
# Simple mailer for job failures (and other admin notifications)
class FailureMailer < ActionMailer::Base
  default to: Settings::FailureNotificationsToEmail,
          from: Settings::NotificationsFromEmail || Settings::AdminEmail,
          content_type: 'text/plain'

  def notify_job_failure(job)
    options = {
      body: "A failure occurred running a delayed_job on server #{Settings::EnvironmentName}.\n#{job}",
      subject: 'delayed_job failure'
    }
    mail(options)
  end
end
