module Seeds
  module CleanAppConfigs
    def self.do_last
      true
    end

    def self.clean_app_configs
      skip_ids = []
      Admin::AppConfiguration.active.each do |ac|
        next if skip_ids.include? ac.id

        ac.role_name = nil if ac.role_name.blank?
        ac.name = nil if ac.name.blank?

        other = Admin::AppConfiguration.active.where(
          app_type_id: ac.app_type_id,
          role_name: ac.role_name || [nil, ''],
          name: ac.name || [nil, ''],
          user_id: ac.user_id
        ).where.not(
          id: ac.id
        )

        other.each do |o|
          skip_ids << o.id
          o.current_admin = auto_admin
          o.disabled = true
          done = o.save
          log "Disabled duplicate app config #{o.id}" if done
        end

        next unless ac.changed?

        begin
          log "Updated app config #{ac.id}" if ac.save
        rescue FphsException => e
          log "ERROR: Failed to update app config #{ac.id} - #{e}"
        end
      end
    end

    def self.setup
      log "In #{self}.setup"

      clean_app_configs
    end
  end
end
