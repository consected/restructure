module Seeds
  module ReportUserNotificationsbNav
    def self.do_last
      true
    end

    def self.add_values(values)
      values.each do |v|
        res = Admin::PageLayout.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_templates
      options = <<~END_TEXT
        nav:
          links:
          - icon: envelope
            url: "/reports/user__my_notifications"
            resource_name: user__my_notifications
            resource_type: report

      END_TEXT

      values = [

        {
          layout_name: 'nav', panel_name: 'all', panel_label: 'Home',
          options: options
        }

      ]

      add_values values
    end

    def self.setup
      log "In #{self}.setup"

      if  !Admin::PageLayout.find_by(layout_name: 'nav', panel_name: 'all', panel_label: 'Home')
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
