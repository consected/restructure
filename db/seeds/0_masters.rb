require_dependency 'master'
module Seeds
  module Masters

    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      unless Master.where(id: -1).first
        Master.create! id: -1, current_user: User.active.first
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

    end
  end
end
