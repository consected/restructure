# frozen_string_literal: true

module Users
  class PasswordChanged
    class << self
      # Class attribute settings are set by the initializer user_reminders.rb
      attr_accessor :password_changed_defaults
    end

    # Set up the notification email when the user tries to change the password
    # @param [User] user
    def self.notify(user)
      Rails.logger.info("Setting up the notification when a user tries to change the password. User #{user.email}")
      HandlePasswordChangedNotificationJob.perform_now(user)
    end

  end
end
