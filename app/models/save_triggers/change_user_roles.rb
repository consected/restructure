# frozen_string_literal: true

class SaveTriggers::ChangeUserRoles < SaveTriggers::SaveTriggersBase
  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids

  def self.config_def(if_extras: {})
    # {
    #   name: 'part of directory name or array of attribute names to use to generate directory name (value used directly if attribute not found)',
    #   label: 'human name',
    #   create_with_role: 'role name',
    #   if: if_extras
    # }
  end

  def initialize(config, item)
    super

    @add_names = config[:add_role_names]
    @remove_names = config[:remove_role_names]
  end

  def perform
    @add_names&.each do |role_def|
      role_name, app_type_id = handle_role_def(role_def)

      item.current_user.user_roles.create(
        app_type_id: app_type_id,
        role_name: role_name,
        current_admin: use_admin
      )
    end

    @remove_names&.each do |role_def|
      role_name, app_type_id = handle_role_def(role_def)

      item.current_user.user_roles.active.find_by(
        app_type_id: app_type_id,
        role_name: role_name
      )&.disable!(use_admin)
    end
  end

  private

  def handle_role_def(role_def)
    if role_def.is_a? Hash
      app_type = role_def[:app_type]
      role_name = role_def[:role_name]
    else
      role_name = role_def
    end

    app_type_id = if app_type
                    Admin::AppType.active_app_types.find_by(name: app_type)&.id
                  else
                    item.current_user.app_type_id
                  end

    raise FphsException, "No active app type found in role definition for app type: #{app_type}" unless app_type_id

    [role_name, app_type_id]
  end

  def use_admin
    Admin.find(1)
  end
end
