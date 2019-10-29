module OptionListHelper

  def app_configuration_options
    Admin::AppConfiguration.configurations
  end

  def app_type_options default_app_type_id: nil
    if default_app_type_id.is_a? Hash
      default_app_type_id = default_app_type_id[:selected]
    end

    options_from_collection_for_select(Admin::AppType.active, 'id', 'label', default_app_type_id)
  end

  def app_type_select_current_item use_current_user: false
    if use_current_user
      {selected: current_user&.app_type_id}
    elsif object_instance&.app_type_id.present?
      {selected: object_instance&.app_type_id}
    elsif params[:filter] && params[:filter].first.first == 'app_type_id' && object_instance&.app_type_id.blank?
      {selected: params[:filter].first.last}
    else
      {}
    end
  end

  def active_user_options default_user_id: nil
    if defined?(object_instance) && object_instance
      default_user_id ||= object_instance.user_id
    end
    options_from_collection_for_select(User.active, 'id', 'email', default_user_id)
  end
end
