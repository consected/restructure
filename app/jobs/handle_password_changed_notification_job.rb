# frozen_string_literal: true

class HandlePasswordChangedNotificationJob < ApplicationJob
  queue_as :default

  def perform(user)
    mn = Messaging::MessageNotification.create! user: user,
                                                recipient_user_ids: [user.id],
                                                layout_template_name: defaults[:layout],
                                                content_template_name: defaults[:content],
                                                message_type: :email,
                                                subject: defaults[:subject],
                                                item: user,
                                                from_user_email: Settings::NotificationsFromEmail

    mn.handle_notification_now logger: Delayed::Worker.logger

  end

  private

  def defaults
    Users::PasswordChanged.password_changed_defaults
  end
end
