class AllowUsersAccessToUserPreferences < ActiveRecord::Migration[5.2]
  def up

    auto_admin = Admin.active.first
    Admin::UserAccessControl.find_or_create_by!(resource_name: 'user_preferences', resource_type: 'table', access: 'create') do |user_access_control|
      user_access_control.current_admin = auto_admin
      user_access_control.disabled = false
    end

    options_yaml = <<~END_OPTIONS
      contains:
        resources:
          - user_preference
    END_OPTIONS

    Admin::PageLayout.find_or_create_by!(layout_name: 'user_profile',
                                         panel_name: 'user_profile_all',
                                         panel_label: 'User Profile Tab') do |page_layout|
      page_layout.options = options_yaml
      page_layout.panel_position = 1
      page_layout.current_admin = auto_admin
      page_layout.disabled = false
    end
  end
end