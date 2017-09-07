module ActivityLogsHelper

  def activity_log_edit_id
    "activity-log-player-contact-phone-edit-form-#{@master_id}-#{@id}"

  end
  def activity_log_edit_form_hash extras={}
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}
    res.merge!({url: "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{object_instance.item_type.pluralize}/#{object_instance.id}", action: :post, remote: true, html: {"data-result-target" => "#activity-log-player-contact-phone-#{@master_id}-#{@id}", "data-template" => "activity-log-player-contact-phone-result-template"}})

    res
  end

  def activity_log_inline_cancel_button class_extras="pull-right"
    logger.info "Doing inline_cancel_button for #{object_instance}"
    
    cancel_href = "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"

    "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}-result-template\" data-toggle=\"scrollto-result\"}></a>".html_safe
  end
end