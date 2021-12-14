# frozen_string_literal: true

module Users
  class Reminders
    class << self
      # Class attribute settings are set by the initializer user_reminders.rb
      attr_accessor :password_expiration_defaults
    end

    def self.prevent_send_to(user)
      Rails.env.test? && !user.email.end_with?('-allow-test-email')
    end

    #
    # Set up the reminder for password expiration for a user
    # @param [User] user
    # @return [HandlePasswordExpirationReminderJob]
    def self.password_expiration(user)
      return if prevent_send_to(user)

      remind_after = password_expiration_defaults[:remind_after]
      Rails.logger.info "Setting up the password expiration reminder for #{remind_after}"
      remind_when = user.password_updated_at + remind_after
      HandlePasswordExpirationReminderJob.set(wait_until: remind_when).perform_later(user) unless Rails.env.development?
    end

    #
    # Set up the repeat reminder for password expiration for a user to go
    # out in a set number of days after the current time
    # @param [User] user
    # @return [HandlePasswordExpirationReminderJob]
    def self.password_expiration_repeat(user)
      return if prevent_send_to(user)

      repeat_reminder_every = password_expiration_defaults[:repeat_reminder_every]
      return if repeat_reminder_every > user.password_expiring_soon?.days

      Rails.logger.info "Setting up the password expiration repeat reminder for #{repeat_reminder_every}"
      send_when = DateTime.now + repeat_reminder_every
      HandlePasswordExpirationReminderJob.set(wait_until: send_when).perform_later(user)
    end
  end
end
