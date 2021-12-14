# frozen_string_literal: true

module Users
  class Confirmations
    class << self
      # Class attribute settings are set by the initializer user_reminders.rb
      attr_accessor :confirmation_defaults
    end

    # Set up the notification email after a user registers
    # @param [User] user
    # @return [HandleUserConfirmationNotificationJob]
    def self.notify(user)
      Rails.logger.info('Setting up the confirmation notification after the user registers.')
      HandleUserConfirmationNotificationJob.set(wait: 1.second).perform_now(user) unless Rails.env.development?
    end

  end
end
