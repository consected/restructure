module AppConfigurationsHelper

  def app_config_text item, default=''
    res = AppConfiguration.value_for(item, current_user)
    return default if res.blank?
    res
  end


  def app_config_set item
    val = AppConfiguration.value_for(item, current_user)
    !val.blank? && val != 'false'
  end

  def app_config_items item, default_list=[]
    res = AppConfiguration.value_for(item, current_user)
    return default_list if res.blank?
    res.split(',').map {|i| i.strip}
  end

end
