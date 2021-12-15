# frozen_string_literal: true

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

  end

  private

  def defaults
    Users::PasswordRecovery.password_recovery_defaults
  end
end
