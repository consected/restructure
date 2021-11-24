# frozen_string_literal: true

module BigSelectFieldHelper
  #
  # Show a big-select field
  # @param [Form] form
  # @param [Hash] data - key value definitions
  # @return [String] - html result
  def big_select_field(form, field, data, subtype: nil, options: {})
    field_id = "#{form.object_name}_#{field}"

    extra_class = options[:hide_popover] ? 'big-select-use-overlay' : ''

    field_html = form.text_field field,
                                 class: "use-big-select #{extra_class}",
                                 readonly: 'readonly',
                                 id: field_id,
                                 data: { 'big-select-subtype': subtype }

    if options[:hide_popover]
      field_overlay = text_field_tag :big_select_overlay, '',
                                     class: 'big-select-overlay',
                                     readonly: 'readonly',
                                     id: "#{field_id}---overlay"
    else
      popover_html = <<~END_HTML
        <span class="glyphicon glyphicon-info-sign big-select-description"
          data-toggle="popover"
          data-trigger="click hover"
          data-content=""></span>
      END_HTML
    end

    <<~END_HTML
      <span class="big-select-wrapper" id="bsw-#{field_id}" data-big-select-field-id="#{field_id}">
        #{field_overlay}
        #{field_html}
        #{popover_html}
        #{big_select_field_data(field_id, subtype, data, options)}
      </span>
    END_HTML
      .html_safe
  end

  def big_select_field_data(field_id, subtype, data, options = nil)
    subtype ||= 'big_select_default'
    options ||= {}

    <<~END_HTML
      <script>
        var big_select_field = $('##{field_id}')[0]
        big_select_field.big_select_options = big_select_field.big_select_options || #{options.to_json.html_safe};
        big_select_field.big_select_hash = big_select_field.big_select_hash || {};
        big_select_field.big_select_hash['#{subtype}'] = #{data.to_json.html_safe};
      </script>
    END_HTML
      .html_safe
  end
end
