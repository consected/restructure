module Seeds
  module PasswordExpirationReminder

    def self.do_last
      true
    end

    def self.add_values values
      values.each do |v|
        res = Admin::MessageTemplate.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_templates
      values = [

        {
          name: 'server password expiration reminder',
          template: "<h2>Your password will expire in the next #{Settings::PasswordReminderDays} days.</h2><p>Login to <b>#{Settings::EnvironmentName}</b> to change your password and avoid being locked out of your account.</p>",
          template_type: 'content',
          message_type: 'email'
        },
        {
          name: 'server password expiration reminder',
          template: "<html>\r\n  <head>\r\n    <title>Password Expiration Reminder</title>\r\n    <style>\r\n     body {font-family: sans-serif; }\r\n    </style>\r\n  </head>\r\n  <body>\r\n   <div>\r\n      {{main_content}}\r\n    </div>\r\n    <div>If you received this email in error, please contact #{Settings::AdminEmail} to ensure we can update our records appropriately.</div>\r\n  </body>\r\n<html>",
          template_type: 'layout',
          message_type: 'email'
        }

      ]

      add_values values
      Rails.logger.info "#{self.name} = #{Admin::MessageTemplate.where(name: 'server password expiration reminder').length}"

    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Admin::MessageTemplate.where(name: 'server password expiration reminder').count == 0
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
