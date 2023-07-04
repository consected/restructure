# frozen_string_literal: true

class HandleNewUserAddedNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_or_admin)
    raise FphsException, 'Settings::NotifyEmailOnRegistration not set' unless Settings::NotifyEmailOnRegistration

    subject = Formatter::Substitution.substitute defaults[:subject], data: user_or_admin
    mn = Messaging::MessageNotification.create! recipient_emails: [Settings::NotifyEmailOnRegistration],
                                                layout_template_name: defaults[:layout],
                                                content_template_name: defaults[:content],
                                                content_template_text: defaults[:content_text],
                                                message_type: :email,
                                                subject: subject,
                                                item: user_or_admin,
                                                from_user_email: Settings::NotificationsFromEmail

    mn.handle_notification_now logger: Delayed::Worker.logger
  end

  private

  def defaults
    Users::NewUserAdded.new_user_added_defaults
  end
end
