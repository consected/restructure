# frozen_string_literal: true

module Seeds
  module BUsers
    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      if User.active.first
        log "Did not run #{self}.setup"
      else
        u = User.where(email: Settings::TemplateUserEmail).first
        if u
          u.update! disabled: false, current_admin: auto_admin
        else
          User.create! email: Settings::TemplateUserEmail, first_name: 'template', last_name: 'template', current_admin: auto_admin
        end
        log "Ran #{self}.setup"
      end
    end
  end
end
