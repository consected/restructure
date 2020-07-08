# frozen_string_literal: true

module Users
  class Reminders
    class << self
      attr_accessor :password_expiration_defaults
    end

    def self.password_expiration(user)
      return if Rails.env.test?

      remind_after = password_expiration_defaults[:remind_after]
      Rails.logger.info "Setting up the password expiration reminder for #{remind_after}"
      remind_when = user.password_updated_at + remind_after
      HandlePasswordExpirationReminderJob.set(wait_until: remind_when).perform_later(user)
    end
  end
end
