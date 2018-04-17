module ApplicationHelper


  def object_name
    (@object_name || controller_name.singularize)
  end

  # Namespace safe lower cased name
  def full_object_name
    if controller.class.parent.name != 'Object'
      "#{controller.class.parent.name.underscore}__#{object_name}"
    else
      object_name
    end
  end

  def object_instance
    instance_variable_get("@#{object_name}")
  end

  def hyphenated_name
    controller_name.singularize.hyphenate
  end


  def current_email
    return nil unless current_user || current_admin
    (current_user || current_admin).email
  end

  def env_name
    (ENV['FPHS_ENV_NAME'] || 'unknown').gsub(' ','_').underscore.downcase
  end

  def current_app_type_id_class
    "app-type-id-#{current_user.app_type_id}" if current_user
  end

  def body_classes
    " class=\"#{controller_name} #{action_name} #{env_name} #{current_app_type_id_class}\"".html_safe
  end

  def zip_field_props init={}
    init.merge({pattern: "\\d{5,5}(-\\d{4,4})?"})
  end

  def common_inline_cancel_button class_extras="pull-right"

    if object_instance.id
      cancel_href = "/masters/#{object_instance.master_id}/#{controller_name}/#{object_instance.id}"
    else
      cancel_href = "/masters/#{object_instance.master_id}/#{controller_name}/cancel"
    end

    "<a class=\"show-entity show-#{hyphenated_name} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{hyphenated_name}-id=\"#{object_instance.id}\" data-result-target=\"##{hyphenated_name}-#{@master.id}-#{@id}\" data-template=\"#{hyphenated_name}-result-template\" ></a>".html_safe
  end

  def common_edit_form_id
    "#{hyphenated_name}-edit-form-#{@master.id}-#{@id}"
  end

  def common_edit_form_hash extras={}
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}
    res[:html].merge!("data-result-target" => "##{hyphenated_name}-#{@master.id}-#{@id}, [form-res-id='#{hyphenated_name}-#{@master.id}-#{@id}']", "data-template" => "#{hyphenated_name}-result-template")
    res
  end

  def edit_form_hash extras={}
    send("#{edit_form_helper_prefix}_edit_form_hash", extras)
  end

  def edit_form_id
    send("#{edit_form_helper_prefix}_edit_form_id")
  end


  def inline_cancel_button class_extras="pull-right"
      send("#{edit_form_helper_prefix}_inline_cancel_button", class_extras)
  end

  def admin_edit_controls
    "<div class=\"admin-edit-controls\">
      #{link_to "cancel", url_for(action: :edit)}
      #{link_to "admin menu", '/'}
      </div>
    ".html_safe

  end

  def show_caption_before key
    @caption_before[key].gsub("\n","<br/>").html_safe
  end

end
