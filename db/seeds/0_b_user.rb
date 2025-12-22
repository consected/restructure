# frozen_string_literal: true

module Seeds
  module BUsers
    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"
      tue = Settings::TemplateUserEmail&.downcase
      if User.active.find_by(email: tue)
        log 'Did not setup template user'
      else
        u = User.find_by(email: tue)
        if u
          u.update! disabled: false, current_admin: Seeds.auto_admin
        else
          User.create! email: tue, first_name: 'template', last_name: 'template', current_admin: Seeds.auto_admin
        end
        log "Ran #{self}.setup"
      end

      if Settings::AllowUsersToRegister
        # Create registration template user required when users are allowed to register.
        dute = Settings::DefaultUserTemplateEmail&.downcase
        if User.active.find_by(email: dute)
          log 'Did not setup registration template user'
        else
          if (template_user = User.find_by(email: dute))
            template_user.update! disabled: false, current_admin: Seeds.auto_admin
          else
            template_user = User.create!(email: dute, first_name: 'registration', last_name: 'template', current_admin: Seeds.auto_admin)
            # creates the registration template user role
            app_type = Admin::AppType.find_by(name: 'zeus')
            role_name = 'user'
            Admin::UserRole.add_to_role(template_user, app_type, role_name, Seeds.auto_admin)
            # TODO: Should creating the UserAccessControl for the registration template user belong here?
            Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: 'general', resource_name: 'app_type', role_name: role_name, access: :read, current_admin: Seeds.auto_admin)
          end
          log "Ran #{self}.setup"
        end
      end

      bue = Settings::BatchUserEmail&.downcase
      if User.active.find_by(email: bue)
        log 'Did not setup batch user'
      else
        u = User.find_by(email: bue)
        if u
          u.update! disabled: false, current_admin: Seeds.auto_admin
        else
          User.create! email: bue, first_name: 'batch', last_name: 'system-user', current_admin: Seeds.auto_admin
        end
        log "Ran #{self}.setup"
      end
    end
  end
end
