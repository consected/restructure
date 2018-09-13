module OptionListHelper

  def app_configuration_options
    Admin::AppConfiguration.configurations
  end

  def app_type_options
    Admin::AppType.active.map{|a| [a.label, a.id]}
  end

  def active_user_options
    options_from_collection_for_select(User.active, 'id', 'email', object_instance.user_id)
  end
end
