# frozen_string_literal: true

Rails.application.config.to_prepare do
  # Set up the Users::Reminders configurations by setting the class attributes
  Users::Reminders.password_expiration_defaults = {
    content: 'server password expiration reminder',
    layout: 'general server notification',
    subject: 'Password Expiration Reminder',
    remind_after: (Settings::PasswordAgeLimit - Settings::PasswordReminderDays).days,
    repeat_reminder_every: Settings::PasswordReminderRepeatDays.days
  }

  # TODO: should I move to a more specifically named initializer?
  # Set up the Users::Confirmations notifications by setting the class attributes
  Users::Confirmations.confirmation_defaults = {
    content: 'server registration confirmation',
    layout: 'general server notification',
    subject: 'Registration Confirmation Notification'
  }

  # TODO: should I move to a more specifically named initializer?
  # Set up the Users::PasswordRecovery notifications by setting the class attributes
  Users::PasswordRecovery.password_recovery_defaults = {
    content: 'server password reset instructions',
    layout: 'general server notification',
    subject: 'Password Reset Instructions'
  }

  # TODO: should I move to a more specifically named initializer?
  # Set up the Users::PasswordChanged notifications by setting the class attributes
  Users::PasswordChanged.password_changed_defaults = {
    content: 'server password changed',
    layout: 'general server notification',
    subject: 'Password Changed Instructions'
  }

  # Optionally can remove *content_text:* and replace with *content:* specifying a content template name
  Users::NewUserAdded.new_user_added_defaults = {
    content_text: 'A new {{class_name}} was registered: {{email}}',
    layout: 'general server notification',
    subject: 'New {{class_name}} registered'
  }
end
