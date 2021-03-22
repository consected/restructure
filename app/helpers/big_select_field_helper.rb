# frozen_string_literal: true

module BigSelectFieldHelper
  #
  # Show a big-select field
  # @param [Form] form
  # @param [Hash] data - key value definitions
  # @return [String] - html result
  def big_select_field(form, field, data)
    field_html = form.text_field field, class: 'use-big-select', readonly: 'readonly'
    <<~END_SQL
      <span class="big-select-wrapper">
        #{field_html}
        <span class="glyphicon glyphicon-info-sign big-select-description"
          data-toggle="popover"
          title="" data-content=""></span>
        <script>
          $('#admin_app_configuration_name')[0].big_select_hash = #{data.to_json.html_safe};
        </script>
      </span>
    END_SQL
      .html_safe
  end
end
