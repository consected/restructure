module Users
  class Reminders

    def self.password_expiration_defaults
      @password_expiration_defaults
    end

    def self.password_expiration_defaults=d
      @password_expiration_defaults = d
    end

    def self.password_expiration user

      remind_after = password_expiration_defaults[:remind_after]
      Rails.logger.info "Setting up the password expiration reminder for #{remind_after}"
      remind_when = user.password_updated_at + remind_after
      HandlePasswordExpirationReminderJob.set(wait_until: remind_when).perform_later(user)

    end

  end

end
