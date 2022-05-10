# frozen_string_literal: true

module Seeds
  module BUsers
    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      if User.active.find_by(email: Settings::TemplateUserEmail)
        log 'Did not setup template user'
      else
        u = User.find_by(email: Settings::TemplateUserEmail)
        if u
          u.update! disabled: false, current_admin: auto_admin
        else
          User.create! email: Settings::TemplateUserEmail, first_name: 'template', last_name: 'template', current_admin: auto_admin
        end
        log "Ran #{self}.setup"
      end

      if Settings::AllowUsersToRegister
        # Create registration template user required when users are allowed to register.
        if User.active.find_by(email: Settings::DefaultUserTemplateEmail)
          log 'Did not setup registration template user'
        else
          if (template_user = User.find_by(email: Settings::DefaultUserTemplateEmail))
            template_user.update! disabled: false, current_admin: auto_admin
          else
            template_user = User.create!(email: Settings::DefaultUserTemplateEmail, first_name: 'registration', last_name: 'template', current_admin: auto_admin)
            # creates the registration template user role
            app_type = Admin::AppType.find_by(name: 'zeus')
            role_name = 'user'
            Admin::UserRole.add_to_role(template_user, app_type, role_name, auto_admin)
            # TODO: Should creating the UserAccessControl for the registration template user belong here?
            Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: 'general', resource_name: 'app_type', role_name: role_name, access: :read, current_admin: auto_admin)
          end
          log "Ran #{self}.setup"
        end
      end

      if User.active.find_by(email: Settings::BatchUserEmail)
        log 'Did not setup batch user'
      else
        u = User.find_by(email: Settings::BatchUserEmail)
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
