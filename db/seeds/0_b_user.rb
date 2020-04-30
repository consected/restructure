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
        User.create! email: 'template@template', first_name: 'template', last_name: 'template', current_admin: auto_admin
        log "Ran #{self}.setup"
      end
    end
  end
end
