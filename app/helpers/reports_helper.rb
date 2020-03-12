# frozen_string_literal: true

module ReportsHelper
  def report_edit_btn(id)
    link_to '', edit_report_path(id, report_id: @report.id, filter: params[:filter]), remote: true, class: 'edit-entity glyphicon glyphicon-pencil'
  end

  def report_edit_cancel
    link_to '', '#', id: 'report-edit-cancel', class: 'btn btn-default glyphicon glyphicon-remove report-edit-cancel'
  end

  def report_field(name, type, value, options = {})
    use_dropdown = nil

    if type.is_a? String
      type_string = type
      return nil
    elsif type.is_a? Hash
      type_string = type.first.first
      type_val = type.first.last || {}
      if type_string == 'config_selector'
        use_dropdown = true
      else
        c = begin
              Classification.const_get(type_string.to_s.classify)
            rescue StandardError
              nil
            end
      end
    end

    value ||= FieldDefaults.calculate_default(@report, type_val['default'], type_string)

    if c&.respond_to?(:all_name_value_enable_flagged)
      if type_val['item_type'] == 'all'
        type_filter = nil
      elsif type_val['item_type']
        type_filter = { item_type: type_val['item_type'] }

      elsif type_val['conditions']
        type_filter = type_val['conditions']
      end

      if type_val.key? 'disabled'
        type_filter ||= {}
        type_filter[:disabled] = false
      end

      unless @report_page
        type_filter ||= {}
        type_filter[:disabled] = false
      end
      use_dropdown = options_for_select(c.all_name_value_enable_flagged(type_filter), value)
    elsif use_dropdown
      use_dropdown = options_for_select(type_val['selections'], value)
    end

    main_field = if type_val['label']
                   label_tag type_val['label']
                 else
                   label_tag name
                 end

    if type_val['multiple'] == 'multiple' || type_val['multiple'] == 'multiple-regex'
      if use_dropdown
        options.merge!(multiple: true)
        main_field << select_tag("search_attrs[#{name}]", use_dropdown, options)
      else
        options.merge!(type: type_string, class: 'form-control no-auto-submit', data: { attribute: name })
        main_field << text_field_tag("multiple_attrs[#{name}]", '', options)
        main_field << link_to('+', "add_multiple_attrs[#{name}]", data: { attribute: name }, class: 'btn btn-default add-btn multivalue-field-add', title: 'add to search')
        v = value
        v = value.join("\n") if value.is_a? Array
        main_field << text_area_tag("search_attrs[#{name}]", v, class: 'auto-grow')

      end
    else
      if use_dropdown
        options.merge!(include_blank: 'select')
        main_field << select_tag("search_attrs[#{name}]", use_dropdown, options)
      else
        options.merge!(type: type_string, class: 'form-control')
        main_field << text_field_tag("search_attrs[#{name}]", value, options)
      end
    end
  end
end
