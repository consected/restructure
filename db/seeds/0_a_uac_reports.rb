module Seeds
  module UserAccessControlReports


    def self.do_first
      true
    end

    def self.setup
      log "In #{self}.setup"

      if Application.version <= '7.3.82'

        valid_user_access_controls = Admin::UserAccessControl.valid_resources

        valid_user_access_controls.where(resource_type: :report).each do |u|
          rn = u.resource_name
          if rn.present?
            unless rn.include?('_')
              u.update resource_name: Report.resource_name_for_named_report(rn), current_admin: auto_admin
            end
          end
        end


        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

    end
  end
end
