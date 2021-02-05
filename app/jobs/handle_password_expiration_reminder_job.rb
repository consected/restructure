# frozen_string_literal:true

#
# Perform a password expiration reminder as a background job
# Background job is set up to run in the future when the password
# is changed, allowing the app to forget about it until the notification
# is required.

class HandlePasswordExpirationReminderJob < ApplicationJob
  # don't retry_on FphsException, since there is too much risk of repeatedly
  # sending emails to users
  queue_as :default

  #
  # Perform the background job, sending a notification to the supplied user.
  # It is possible that a user has already changed their password, so just return
  # if this notification is no longer needed.
  # @param [User] user - the user to notify
  def perform(user)
    unless user.password_expiring_soon?
      Delayed::Worker.logger.info "User password is not expiring soon. Don't bother to remind yet, since there" \
                                  'is another job coming up in the future to do it.'
      return
    end

    puts "Performing job on #{user.inspect}"
    defaults = Users::Reminders.password_expiration_defaults || {}
    layout = defaults[:layout]

    unless layout
      Delayed::Worker.logger.info 'No layout template name has been set for password expiration reminder'
      return
    end

    unless Messaging::MessageNotification.layout_template layout
      Delayed::Worker.logger.info 'No layout template defined for the password expiration reminder,' \
                                  "with name #{layout}"
      return
    end

    # Set up the message notification using the message template
    mn = Messaging::MessageNotification.create! user: user,
                                                recipient_user_ids: [user.id],
                                                layout_template_name: layout,
                                                content_template_name: defaults[:content],
                                                message_type: :email,
                                                subject: defaults[:subject],
                                                item: user

    # Send this now
    mn.handle_notification_now logger: Delayed::Worker.logger
  end
end
