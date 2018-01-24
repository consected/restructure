module AppConfigurationsHelper

  def app_config_text item, default=''
    res = AppConfiguration.value_for(item)
    return default if res.blank?
    res
  end

  def app_config_title item
    AppConfiguration.value_for(item).titleize
  end

  def app_config_set item
    !AppConfiguration.value_for(item).blank? && AppConfiguration.value_for(item) != 'false'
  end

end
