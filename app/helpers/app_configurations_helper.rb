module AppConfigurationsHelper
  def app_config_text(item, default = '', alt_user: false)
    user = app_config_user_to_use(alt_user)
    res = Admin::AppConfiguration.value_for(item, user)
    return default if res.blank?

    res
  end

  def app_config_set(item, alt_user: false)
    user = app_config_user_to_use(alt_user)
    val = Admin::AppConfiguration.value_for(item, user)
    !val.blank? && val != 'false'
  end

  def app_config_items(item, default_list = [], alt_user: false)
    user = app_config_user_to_use(alt_user)
    res = Admin::AppConfiguration.value_for(item, user)
    return default_list if res.blank?

    res.split(',').map { |i| i.strip }
  end

  def app_config_user_to_use(alt_user)
    if alt_user != false
      alt_user
    else
      current_user
    end
  end
end
