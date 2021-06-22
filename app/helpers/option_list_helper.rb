# frozen_string_literal: true

module OptionListHelper
  def app_configuration_options
    Admin::AppConfiguration.configurations
  end

  def app_type_options(default_app_type_id: nil)
    default_app_type_id = default_app_type_id[:selected] if default_app_type_id.is_a? Hash

    options_from_collection_for_select(Admin::AppType.active_app_types, 'id', 'label', default_app_type_id)
  end

  def app_type_select_current_item(use_current_user: false)
    if use_current_user
      { selected: current_user&.app_type_id }
    elsif object_instance&.app_type_id.present?
      { selected: object_instance&.app_type_id }
    elsif filter_params_hash&.first&.first == 'app_type_id' && object_instance&.app_type_id.blank?
      { selected: filter_params_hash&.first&.last }
    else
      {}
    end
  end

  def active_user_options(default_user_id: nil)
    default_user_id ||= object_instance.user_id if defined?(object_instance) && object_instance
    options_from_collection_for_select(User.active, 'id', 'email', default_user_id)
  end
end
