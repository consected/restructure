module Seeds
  module AllowAccessToUserPreferences

    def self.do_last
      true
    end

    def self.create_user_access_control_user_preferences
      Admin::UserAccessControl.find_or_create_by!(resource_name: 'user_preferences',
                                                  resource_type: 'table',
                                                  access: 'create') do |user_access_control|
        user_access_control.current_admin = auto_admin
        user_access_control.disabled = false
      end
    end

    def self.create_page_layout_for_user_preferences
      options_yaml = <<~END_OPTIONS
        contains:
          resources:
            - user_preference
      END_OPTIONS
      options_yaml.freeze

      Admin::PageLayout.find_or_create_by!(layout_name: 'user_profile',
                                           panel_name: 'user_profile_all') do |page_layout|
        page_layout.panel_label = 'User Profile Tab'
        page_layout.options = options_yaml
        page_layout.panel_position = 1
        page_layout.current_admin = auto_admin
        page_layout.disabled = false
      end
    end

    def self.setup
      log "In #{self}.setup"
      create_user_access_control_user_preferences
      create_page_layout_for_user_preferences
      log "Out #{self}.setup"
    end
  end
end
