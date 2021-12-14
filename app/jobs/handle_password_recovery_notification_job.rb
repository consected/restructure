# frozen_string_literal: true

# Handle the password expirations that have been scheduled for the future
# when a new user was created or password was reset.
# It is possible that a user will have reset their password since this original
# job was created, so the job ensures that nothing is sent if the password is not
# actually within the reminder period.
# When sent, a reminder job will set up a new future reminder job, to provide a repeating
# reminder on a set frequency, which will continue until:
#   - the user resets their password
#   - the password expires
#   - the password will expire before the repeat reminder would be sent
class HandlePasswordRecoveryNotificationJob < ApplicationJob
  queue_as :default

  def perform(user)
    mn = Messaging::MessageNotification.create! user: user,
                                                recipient_user_ids: [user.id],
                                                layout_template_name: defaults[:layout],
                                                content_template_name: defaults[:content],
                                                message_type: :email,
                                                subject: defaults[:subject],
                                                item: user

    mn.handle_notification_now logger: Delayed::Worker.logger

    Users::PasswordRecovery.notify(user)
  end

  private

  def defaults
    Users::PasswordRecovery.password_recovery_defaults
  end
end
