module Seeds
  module ReportUserNotificationsbUac
    def self.do_last
      true
    end

    def self.add_values(values)
      values.each do |v|
        res = Admin::UserAccessControl.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_templates
      values = [

        {
          resource_type: 'report', access: 'read', resource_name: 'user__my_notifications'
        }

      ]

      add_values values
    end

    def self.setup
      log "In #{self}.setup"

      if  !Admin::UserAccessControl.find_by(resource_type: 'report', access: 'read', resource_name: 'user__my_notifications')
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
