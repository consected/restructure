class HandlePasswordExpirationReminderJob < ApplicationJob

  # retry_on FphsException
  queue_as :default

  def perform(user)

    if user.password_expiring_soon?
      puts "Performing job on #{user.inspect}"
      ped = Users::Reminders.password_expiration_defaults

      unless ped && ped[:layout]
        Delayed::Worker.logger.info "No layout template name has been set for password expiration reminder"
        return
      end
      unless Messaging::MessageNotification.layout_template ped[:layout]
        Delayed::Worker.logger.info "No layout template defined for the password expiration reminder, with name #{ped[:layout]}"
        return
      end


      mn = Messaging::MessageNotification.create! user: user, recipient_user_ids: [user.id], layout_template_name: ped[:layout],
                                                  content_template_name: ped[:content], message_type: :email, subject: ped[:subject],
                                                  item: user

      mn.handle_notification_now logger: Delayed::Worker.logger
    else
      Delayed::Worker.logger.info "User password is not expiring soon. Don't bother to remind yet, since there is another job coming up in the future to do it."
    end
  end
end
