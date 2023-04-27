# frozen_string_literal: true

module ActivityLogsHelper
  def activity_log_edit_form_id
    if @option_type_name
      # The extra log type was passed as a param for a new item
      extra_type = "-#{@option_type_name.hyphenate}"
    elsif object_instance.extra_log_type
      # The object includes the extra log type
      extra_type = "-#{object_instance.extra_log_type.hyphenate}"
    elsif !@item
      extra_type = '-blank-log'
    end

    "#{@implementation_class.name.ns_hyphenate}#{extra_type}-edit-form-#{@master_id}-#{@id}"
  end

  def activity_log_edit_form_hash(extras = {})
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}

    if @option_type_name
      extra_type_param = "?extra_type=#{@option_type_name.hyphenate}"
      extra_type = "-#{@option_type_name.hyphenate}"
    end

    if @item
      res.merge!(
        url: "/masters/#{@master_id}/#{@item.item_type_path.pluralize}/#{@item_id}/#{object_instance.item_type_path}/#{object_instance.id}#{extra_type_param}", action: :post, remote: true, html: {
          'data-result-target' => "##{@implementation_class.name.ns_hyphenate}#{extra_type}-#{@master_id}-#{@id}", 'data-template' => "#{@implementation_class.name.ns_hyphenate}#{extra_type}-result-template", 'data-use-alt-result-key' => "#{@implementation_class.name.ns_underscore}_primary"
        }
      )
    else
      extra_type ||= '-blank-log'
      res.merge!(
        url: "/masters/#{@master_id}/#{object_instance.item_type_path}/#{object_instance.id}#{extra_type_param}", action: :post, remote: true, html: {
          'data-result-target' => "##{@implementation_class.name.ns_hyphenate}#{extra_type}-#{@master_id}-#{@id}", 'data-template' => "#{@implementation_class.name.ns_hyphenate}#{extra_type}-result-template", 'data-use-alt-result-key' => "#{@implementation_class.name.ns_underscore}#{extra_type.underscore}"
        }
      )
    end
    res
  end

  def activity_log_inline_cancel_button(class_extras = nil, link_text = nil)
    if @option_type_name
      extra_type_param = "?extra_type=#{@option_type_name.hyphenate}"
      extra_type = "-#{@option_type_name.hyphenate}"
    end

    button_class = 'glyphicon glyphicon-remove-sign inline-cancel'
    class_extras ||= 'pull-right' unless link_text

    if @id
      if @item
        cancel_href = "/masters/#{@master_id}/#{@item.item_type.pluralize}/#{@item_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}#{extra_type_param}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras}  #{link_text ? '' : button_class}\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}#{extra_type}-result-template\" data-toggle=\"scrollto-result\"}>#{link_text}</a>".html_safe
      else
        extra_type ||= '-blank-log'
        cancel_href = "/masters/#{@master_id}/#{primary_model.to_s.underscore.pluralize}/#{@id}"
        "<a class=\"show-entity show-#{full_object_name.hyphenate} #{class_extras}  #{link_text ? '' : button_class}\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{full_object_name.hyphenate}-id=\"#{@id}\" data-result-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-#{@id}\" data-template=\"#{full_object_name.hyphenate}#{extra_type}-result-template\" data-toggle=\"scrollto-result\" data-use-alt-result-key=\"#{full_object_name.underscore}#{extra_type.underscore}\"}>#{link_text}</a>".html_safe
      end
    elsif @item
      "<a class=\"show-entity show-#{hyphenated_name} #{class_extras}  #{link_text ? '' : button_class}\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-\">#{link_text}</a>".html_safe
    elsif params[:references] && params[:references][:record_id] && !params[:references][:new_outside_this]
      # An embedded new item
      "<a class=\"show-entity show-#{hyphenated_name} #{class_extras}  #{link_text ? '' : button_class} in--embedded-new\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{params[:references][:record_type].ns_hyphenate.pluralize}-#{params[:references][:record_id]}- .new-block > div\">#{link_text}</a>".html_safe
    else
      extra_type ||= '-blank-log'
      "<a class=\"show-entity show-#{hyphenated_name} #{class_extras}  #{link_text ? '' : button_class}\" title=\"cancel\" data-master-id=\"#{@master_id}\" data-item-id=\"#{@item_id}\" data-toggle=\"clear\" data-target=\"##{full_object_name.hyphenate}#{extra_type}-#{@master_id}-\">#{link_text}</a>".html_safe
    end
  end

  def selectable_model_reference
    params[:references] && params[:references][:allow_select] == 'true'
  end

  def model_reference_fields(f)
    res = ''
    ref_params = params[:references]
    if ref_params.present?
      ref_record_type = ref_params[:record_type]
      ref_record_id = ref_params[:record_id]
    end
    if ref_record_id && ref_record_type
      res += f.hidden_field(:ref_record_type, value: ref_record_type)
      res += f.hidden_field(:ref_record_id, value: ref_record_id)
    end

    res.html_safe
  end
end
