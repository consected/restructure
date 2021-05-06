# frozen_string_literal: true

module BigSelectFieldHelper
  #
  # Show a big-select field
  # @param [Form] form
  # @param [Hash] data - key value definitions
  # @return [String] - html result
  def big_select_field(form, field, data, subtype: nil)
    field_id = "#{form.object_name}_#{field}"

    field_html = form.text_field field,
                                 class: 'use-big-select',
                                 readonly: 'readonly',
                                 id: field_id,
                                 data: { 'big-select-subtype': subtype }

    <<~END_HTML
      <span class="big-select-wrapper" id="bsw-#{field_id}" data-big-select-field-id="#{field_id}">
        #{field_html}
        <span class="glyphicon glyphicon-info-sign big-select-description"
          data-toggle="popover"
          data-trigger="click hover"
          data-content=""></span>
        #{big_select_field_data(field_id, subtype, data)}
      </span>
    END_HTML
      .html_safe
  end

  def big_select_field_data(field_id, subtype, data)
    subtype ||= 'big_select_default'

    <<~END_HTML
      <script>
        var big_select_field = $('##{field_id}')[0]
        big_select_field.big_select_hash = big_select_field.big_select_hash || {}
        big_select_field.big_select_hash['#{subtype}'] = #{data.to_json.html_safe};
      </script>
    END_HTML
      .html_safe
  end
end
