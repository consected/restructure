# frozen_string_literal: true

#
# Default configurations for user password expiration reminders
# Set the message template (content, layout), subject and the number
# of days before expiration to remind the user to change their password
# (remind_after)
Rails.application.config.to_prepare do
  Users::Reminders.password_expiration_defaults = {
    content: 'server password expiration reminder',
    layout: 'server password expiration reminder',
    subject: 'Password Expiration Reminder',
    remind_after: (Settings::PasswordAgeLimit - Settings::PasswordReminderDays).days
  }
end
