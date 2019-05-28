module Seeds
  module Users

    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      unless User.active.first
        User.create! email: 'template@template', first_name: 'template', last_name: 'template', current_admin: auto_admin
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

    end
  end
end
