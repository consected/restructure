# frozen_string_literal: true

class SaveTriggers::ChangeUserRoles < SaveTriggers::SaveTriggersBase
  attr_accessor :role, :users, :layout_template, :content_template, :message_type, :subject, :receiving_user_ids,
                :app_type_id, :role_name, :for_user

  def self.config_def(if_extras: {}); end

  def initialize(config, item)
    super

    @add_names = config[:add_role_names]
    @remove_names = config[:remove_role_names]
  end

  def perform
    @add_names&.each do |role_def|
      role_name, app_type_id, for_user = handle_role_def(role_def)

      for_user.user_roles.create(
        app_type_id:,
        role_name:,
        current_admin: use_admin
      )
    end

    @remove_names&.each do |role_def|
      role_name, app_type_id, for_user = handle_role_def(role_def)

      for_user.user_roles.active.find_by(
        app_type_id:,
        role_name:
      )&.disable!(use_admin)
    end
  end

  private

  #
  # Handle the job definition using the options
  #   app_type
  #   role_name
  #   for_user (defaults to item.current_user if not set)
  # If for_user was not set, default to the current user
  def handle_role_def(role_def)
    if role_def.is_a? Hash
      app_type = role_def[:app_type]
      self.role_name = role_def[:role_name]
      self.for_user = role_def[:for_user]
    else
      self.role_name = role_def
    end

    self.app_type_id = if app_type
                         Admin::AppType.active_app_types.find_by(name: app_type)&.id
                       else
                         item.current_user.app_type_id
                       end

    raise FphsException, "No active app type found in role definition for app type: #{app_type}" unless app_type_id

    self.role_name = FieldDefaults.calculate_default(item, role_name) if role_name

    self.for_user = if for_user
                      FieldDefaults.calculate_default(item, for_user)
                    else
                      item.current_user
                    end

    self.for_user = case for_user
                    when Integer
                      User.active.find_by(id: for_user)
                    when String
                      User.active.find_by(email: for_user&.downcase)
                    else
                      for_user
                    end

    [role_name, app_type_id, for_user]
  end

  def use_admin
    Admin.find(1)
  end
end
