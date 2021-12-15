# frozen_string_literal: true

module Users
  class PasswordRecovery
    class << self
      # Class attribute settings are set by the initializer user_reminders.rb
      attr_accessor :password_recovery_defaults
    end

    # Set up the notification email when the user tries to recover the password
    # @param [User] user
    # @return [HandlePasswordRecoveryNotificationJob]
    def self.notify(user)
      Rails.logger.info('Setting up the notification when a user tries to recover the password.')
      HandlePasswordRecoveryNotificationJob.perform_now(user) #unless Rails.env.development?
    end

  end
end
