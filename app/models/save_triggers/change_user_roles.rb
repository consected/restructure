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
    @add_names&.each do |role_name|
      item.current_user.user_roles.create(
        app_type_id: item.current_user.app_type_id,
        role_name: role_name,
        current_admin: use_admin
      )
    end

    @remove_names&.each do |role_name|
      item.current_user.user_roles.active.where(
        app_type_id: item.current_user.app_type_id,
        role_name: role_name
      ).first&.disable!(use_admin)
    end
  end

  private

  def use_admin
    Admin.find(1)
  end
end
