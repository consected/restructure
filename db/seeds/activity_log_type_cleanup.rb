module Seeds
  module ActivityLogTypeCleanup
    def self.setup
      log "In #{self}.setup"

      ActivityLog.active.where(rec_type: '').update_all(rec_type: nil)
      ActivityLog.active.where(process_name: '').update_all(process_name: nil)
    end
  end
end
