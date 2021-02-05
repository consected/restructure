# frozen_string_literal: true

module Users
  #
  # Password reminder set up
  class Reminders
    class << self
      attr_accessor :password_expiration_defaults
    end

    def self.prevent_send_to(user)
      Rails.env.test? && !user.email.end_with?('-allow-test-email')
    end

    #
    # Set up password expiration reminder for the specified user
    # The actual notification sending is handled by a background job. If you are not worried about
    # the mechanics of this, just assume this method sets up that background job for the future.
    # If a change to the reminder mechanism is required, this is probably the place to do it.
    # @param [User] user
    def self.password_expiration(user)
      return if prevent_send_to(user)

      remind_after = password_expiration_defaults[:remind_after]
      Rails.logger.info "Setting up the password expiration reminder for #{remind_after}"
      remind_when = user.password_updated_at + remind_after

      # Set up a background job for the future to send the reminder.
      HandlePasswordExpirationReminderJob.set(wait_until: remind_when).perform_later(user)
    end
  end
end
