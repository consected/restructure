# frozen_string_literal: true

require_dependency 'master'
module Seeds
  module CMasters
    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"
      BUsers.setup
      if Master.where(id: -1).first
        log "Did not run #{self}.setup"
      else
        Master.create! id: -1, current_user: User.active.first
        log "Ran #{self}.setup"
      end
    end
  end
end
