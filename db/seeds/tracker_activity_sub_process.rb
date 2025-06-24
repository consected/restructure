# frozen_string_literal: true

module Seeds
  module TrackerActivitySubProcess

    def self.setup
      log "In #{self}.setup"

      admin = auto_admin

      log '- Handling ExternalIdentifier'
      ExternalIdentifier.active.each do |a|
        a.current_admin = admin
        a.update_tracker_events
      end

      log '- Handling DynamicModel'
      DynamicModel.active.each do |a|
        a.current_admin = admin
        a.update_tracker_events
      end

      log '- Handling ActivityLog'
      ActivityLog.active.each do |a|
        a.current_admin = admin
        a.update_tracker_events
      end
      
    end
  end
end
