# frozen_string_literal: true

# Set up the Users:Reminders configurations by setting the class attributes
Rails.application.config.to_prepare do
  Users::Reminders.password_expiration_defaults = {
    content: 'server password expiration reminder',
    layout: 'server password expiration reminder',
    subject: 'Password Expiration Reminder',
    remind_after: (Settings::PasswordAgeLimit - Settings::PasswordReminderDays).days,
    repeat_reminder_every: Settings::PasswordReminderRepeatDays.days
  }
end
