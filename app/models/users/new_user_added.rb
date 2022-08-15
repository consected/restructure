# frozen_string_literal: true

module Users
  class NewUserAdded
    class << self
      # Class attribute settings are set by the initializer user_reminders.rb
      attr_accessor :new_user_added_defaults
    end

    # Set up the notification email when the user tries to change the password
    # @param [User] user
    def self.notify(user_or_admin)
      Rails.logger.info('Setting up the notification to the administrator when a new user or admin registers.')
      HandleNewUserAddedNotificationJob.perform_now(user_or_admin)
    end
  end
end
