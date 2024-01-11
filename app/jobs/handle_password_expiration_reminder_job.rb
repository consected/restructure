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
class HandlePasswordExpirationReminderJob < ApplicationJob
  queue_as :default

  def perform(user)
    return unless allow_send_to(user)

    mn = Messaging::MessageNotification.create! user: user,
                                                recipient_user_ids: [user.id],
                                                layout_template_name: defaults[:layout],
                                                content_template_name: defaults[:content],
                                                message_type: :email,
                                                subject: defaults[:subject],
                                                item: user,
                                                from_user_email: Settings::NotificationsFromEmail

    mn.handle_notification_now logger: Delayed::Worker.logger

    Users::Reminders.password_expiration_repeat(user)
  end

  private

  def allow_send_to(user)
    return if user.do_not_email

    unless user.password_expiring_soon?
      Delayed::Worker.logger.info "User password is not expiring soon. Don't bother to remind yet, " \
                                  'since there is another job coming up in the future to do it.'
      return
    end

    puts "Performing job on #{user.inspect}" unless Rails.env.test?

    unless defaults && defaults[:layout]
      Delayed::Worker.logger.warn 'No layout template name has been set for password expiration reminder'
      return
    end

    unless Messaging::MessageNotification.layout_template defaults[:layout]
      Delayed::Worker.logger.warn 'No layout template defined for the password expiration reminder, ' \
                                  "with name #{defaults[:layout]}"
      return
    end
    true
  end

  def defaults
    Users::Reminders.password_expiration_defaults
  end
end
