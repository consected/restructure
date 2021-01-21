module Seeds
  module AAppType1
    def self.do_first
      true
    end

    def self.create_app_type
      app_type = Admin::AppType.find_by_id(1)
      return if app_type&.enabled?

      if app_type&.disabled?
        app_type.current_admin = auto_admin
        app_type.disabled = false
        app_type.save!
      end

      return if app_type&.enabled?

      Admin::AppType.create!(
        id: 1,
        name: 'zeus',
        label: 'Zeus',
        disabled: false,
        default_schema_name: 'ml_app',
        current_admin: auto_admin
      )
    end

    def self.setup
      log "In #{self}.setup"
      log "App Type exists?: #{Admin::AppType.active.count}"
      if Rails.env.test? || Admin::AppType.active.count == 0
        create_app_type
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
