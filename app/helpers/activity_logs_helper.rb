module ActivityLogsHelper

  def activity_log_edit_form_id

    if @extra_log_type_name
      # The extra log type was passed as a param for a new item
      extra_type = "-#{@extra_log_type_name.hyphenate}"
    elsif object_instance.extra_log_type
      # The object includes the extra log type
      extra_type = "-#{object_instance.extra_log_type.hyphenate}"
    elsif !@item
      extra_type = '-blank-log'
    end

    "#{@implementation_class.name.ns_hyphenate}#{extra_type}-edit-form-#{@master_id}-#{@id}"

  end

  def activity_log_edit_form_hash extras={}
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}

    if @extra_log_type_name
      extra_type_param = "?extra_type=#{@extra_log_type_name.hyphenate}"
      extra_type = "-#{@extra_log_type_name.hyphenate}"
    end

    if @item
      res.merge!({url: "/masters/#{@master_id}/#{@item.item_type_path.pluralize}/#{@item_id}/#{object_instance.item_type_path}/#{object_instance.id}#{extra_type_param}", action: :post, remote: true, html: {"data-result-target" => "##{@implementation_class.name.ns_hyphenate}#{extra_type}-#{@master_id}-#{@id}", "data-template" => "#{@implementation_class.name.ns_hyphenate}#{extra_type}-result-template"}})
    else
      extra_type ||= '-blank-log'
      res.merge!({url: "/masters/#{@master_id}/#{object_instance.item_type_path}/#{object_instance.id}#{extra_type_param}", action: :post, remote: true, html: {"data-result-target" => "##{@implementation_class.name.ns_hyphenate}#{extra_type}-#{@master_id}-#{@id}", "data-template" => "#{@implementation_class.name.ns_hyphenate}#{extra_type}-result-template", "data-use-alt-result-key" => "#{@implementation_class.name.ns_underscore}#{extra_type.underscore}" }})
    end
    res
  end

  def activity_log_inline_cancel_button class_extras="pull-right"

    if @extra_log_type_name
      extra_type_param = "?extra_type=#{@extra_log_type_name.hyphenate}"
      extra_type = "-#{@extra_log_type_name.hyphenate}"
    end

    if @id
      if @item
        cancel_href = "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}#{extra_type_param}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}#{extra_type}-result-template\" data-toggle=\"scrollto-result\"}></a>".html_safe
      else
        extra_type ||= '-blank-log'
        cancel_href = "/masters/#{@master_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras} glyphicon glyphicon-remove-sign\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}#{extra_type}-result-template\" data-toggle=\"scrollto-result\" data-use-alt-result-key=\"#{full_object_name.hyphenate}-blank-log\"}></a>".html_safe
      end
    else
      if @item
        "<a class=\"show-entity show-#{hyphenated_name} pull-right glyphicon glyphicon-remove-sign\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-\"></a>".html_safe
      else
        extra_type ||= '-blank-log'
        "<a class=\"show-entity show-#{hyphenated_name} pull-right glyphicon glyphicon-remove-sign\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-\"></a>".html_safe
      end
    end
  end

  def model_reference_fields f
    res = ""
    ref_params = params[:references]
    if ref_params.present?
      ref_record_type = ref_params[:record_type]
      ref_record_id = ref_params[:record_id]
    end
    if ref_record_id && ref_record_type
      res << f.hidden_field( :ref_record_type, value: ref_record_type)
      res << f.hidden_field( :ref_record_id, value: ref_record_id)
    end

    res.html_safe
  end
end
