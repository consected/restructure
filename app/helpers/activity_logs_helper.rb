module ActivityLogsHelper

  def activity_log_edit_form_id
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
    if @id
      cancel_href = "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"
      "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}-result-template\" data-toggle=\"scrollto-result\"}></a>".html_safe
    else
      "<a class=\"show-entity show-#{hyphenated_name} pull-right glyphicon glyphicon-remove-sign\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-on-click-show=\"activity_logs_phone_actions-partial@#activity-log-player-contact-phone-#{@master_id}-#{@id}\"></a>".html_safe
    end
  end
end