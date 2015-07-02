module ApplicationHelper
  
  def object_instance
    instance_variable_get("@#{controller_name.singularize}")
  end
  def hyphenated_name
    controller_name.singularize.gsub('_','-')
  end
  
  
  def current_email
    return nil unless current_user || current_admin
    (current_user || current_admin).email
  end
  
  def body_classes
    " class=\"#{controller_name} #{action_name}\"".html_safe
  end
  
  def zip_field_props init={}
    init.merge({pattern: "\\d{5,5}"})
  end
  
  def inline_cancel_button class_extras="pull-right"
    logger.info "Doing inline_cancel_button for #{object_instance}"
    
    if object_instance.id 
      cancel_href = "/masters/#{object_instance.master_id}/#{controller_name}/#{object_instance.id}"
    else
      cancel_href = "/masters/#{object_instance.master_id}/#{controller_name}/cancel"
    end
          
    "<a class=\"show-entity show-#{hyphenated_name} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{hyphenated_name}-id=\"#{object_instance.id}\" data-result-target=\"##{hyphenated_name}-#{@master.id}-#{@id}\" data-template=\"#{hyphenated_name}-result-template\"></a>".html_safe
  end
  
  def edit_form_id
    "#{hyphenated_name}-edit-form-#{@master.id}-#{@id}"
  end
  
  def edit_form_hash extras={}
    res = extras.dup 
    
    res[:remote] = true
    res[:html] ||= {}
    res[:html].merge!("data-result-target" => "##{hyphenated_name}-#{@master.id}-#{@id}", "data-template" => "#{hyphenated_name}-result-template")
    res
  end
  
end
