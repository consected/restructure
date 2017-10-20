module ActivityLogsHelper

  def activity_log_edit_form_id
    if @item
      "#{@al_class.name.ns_hyphenate}-edit-form-#{@master_id}-#{@id}"
    else
      "#{@al_class.name.ns_hyphenate}-blank-log-edit-form-#{@master_id}-#{@id}"
    end

  end
  def activity_log_edit_form_hash extras={}
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}
    if @item
      res.merge!({url: "/masters/#{@master_id}/#{@item.item_type_path.pluralize}/#{@item_id}/#{object_instance.item_type_path}/#{object_instance.id}", action: :post, remote: true, html: {"data-result-target" => "##{@al_class.name.ns_hyphenate}-#{@master_id}-#{@id}", "data-template" => "#{@al_class.name.ns_hyphenate}-result-template"}})
    else
      res.merge!({url: "/masters/#{@master_id}/#{object_instance.item_type_path}/#{object_instance.id}", action: :post, remote: true, html: {"data-result-target" => "##{@al_class.name.ns_hyphenate}-blank-log-#{@master_id}-#{@id}", "data-template" => "#{@al_class.name.ns_hyphenate}-blank-log-result-template", "data-use-alt-result-key" => "#{@al_class.name.ns_underscore}_blank_log" }})
    end
    res
  end

  def activity_log_inline_cancel_button class_extras="pull-right"
    if @id
      if @item
        cancel_href = "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}-result-template\" data-toggle=\"scrollto-result\"}></a>".html_safe
      else
        cancel_href = "/masters/#{@master_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}-blank-log-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}-result-template\" data-toggle=\"scrollto-result\" data-use-alt-result-key=\"#{full_object_name.hyphenate}-blank-log\"}></a>".html_safe
      end
    else
      if @item
        "<a class=\"show-entity show-#{hyphenated_name} pull-right glyphicon glyphicon-remove-sign\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}-#{@master_id}-\"></a>".html_safe
      else
        "<a class=\"show-entity show-#{hyphenated_name} pull-right glyphicon glyphicon-remove-sign\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}-blank-log-#{@master_id}-\"></a>".html_safe
      end
    end
  end
end
