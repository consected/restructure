# frozen_string_literal: true

module Seeds
  module BUsers
    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      if User.active.where(email: Settings::TemplateUserEmail).first
        log 'Did not setup template user'
      else
        u = User.where(email: Settings::TemplateUserEmail).first
        if u
          u.update! disabled: false, current_admin: auto_admin
        else
          User.create! email: Settings::TemplateUserEmail, first_name: 'template', last_name: 'template', current_admin: auto_admin
        end
        log "Ran #{self}.setup"
      end

      if Settings::AllowUsersToRegister
        # Create registration template user required when users are allowed to register.
        if User.active.where(email: Settings::DefaultUserTemplateEmail).first
          log 'Did not setup registration template user'
        else
          if (template_user = User.where(email: Settings::DefaultUserTemplateEmail).first)
            template_user.update! disabled: false, current_admin: auto_admin
          else
            template_user = User.create!(email: Settings::DefaultUserTemplateEmail, first_name: 'registration', last_name: 'template', current_admin: auto_admin)
            # creates the registration template user role
            app_type = Admin::AppType.find_by(name: 'zeus')
            Admin::UserRole.add_to_role(template_user, app_type, 'user', auto_admin)
          end
          log "Ran #{self}.setup"
        end
      end

      if User.active.where(email: Settings::BatchUserEmail).first
        log 'Did not setup batch user'
      else
        u = User.where(email: Settings::BatchUserEmail).first
        if u
          u.update! disabled: false, current_admin: auto_admin
        else
          User.create! email: Settings::BatchUserEmail, first_name: 'batch', last_name: 'system-user', current_admin: auto_admin
        end
        log "Ran #{self}.setup"
      end
    end
  end
end
