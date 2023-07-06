# frozen_string_literal: true

class HandlePasswordRecoveryNotificationJob < ApplicationJob
  queue_as :default

  def perform(user, options)
    mn = Messaging::MessageNotification.create! user: user,
                                                recipient_user_ids: [user.id],
                                                layout_template_name: defaults[:layout],
                                                content_template_name: defaults[:content],
                                                message_type: :email,
                                                subject: defaults[:subject],
                                                item: user,
                                                data: {
                                                  email: user.email,
                                                  reset_password_hash: options[:reset_password_hash]
                                                },
                                                from_user_email: Settings::NotificationsFromEmail

    mn.handle_notification_now logger: Delayed::Worker.logger

  end

  private

  def defaults
    Users::PasswordRecovery.password_recovery_defaults
  end
end
