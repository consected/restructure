module ApplicationHelper
  
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
  
end
