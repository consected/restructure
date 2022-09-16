# frozen_string_literal: true

module BigSelectFieldHelper
  #
  # Show a big-select field.
  # *options* include:
  #   hide_popover: true (show the selected value with an overlay field)
  #   filtered: true (filter the options shown based on the value of another selection field)
  # @param [Form] form
  # @param [Hash] data - key value definitions
  # @param [Symbol] subtype - use an alterative subtype as the default
  # @param [Hash] options
  # @return [String] - html result
  def big_select_field(form, field, data, subtype: nil, options: {})
    @big_select_field_id = nil
    if options[:filtered]
      not_done = true
      field_id = big_select_field_id # "#{form.object_name}_#{field}".to_sym
      res = ''
      data.each do |k, v|
        if not_done
          not_done = false
          res = "#{res} #{big_select_field_main(form, field, v, subtype: k, options: options)}"
        else
          res = "#{res} #{big_select_field_data(form, field_id, k, v)}"
        end
      end
      res.html_safe
    else
      big_select_field_main(form, field, data, subtype: subtype, options: options)
    end
  end

  #
  # Show initial components of big-select field
  # @param [Form] form
  # @param [Hash] data - key value definitions
  # @param [Symbol] subtype - use an alterative subtype as the default
  # @param [Hash] options
  # @return [String] - html result
  def big_select_field_main(form, field, data, subtype: nil, options: {})
    field_id = big_select_field_id # "#{form.object_name}_#{field}"

    hide_popover = options[:hide_popover]
    extra_class = hide_popover ? 'big-select-use-overlay' : ''

    tf_options = {
      class: "use-big-select #{extra_class}",
      readonly: 'readonly',
      id: field_id,
      data: { 'big-select-subtype': subtype }
    }

    field_html = if options[:no_instance]
                   text_field_tag field, options[:value], tf_options
                 else
                   form.text_field field, tf_options
                 end

    if hide_popover
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
        #{big_select_field_data(subtype, data, options)}
      </span>
    END_HTML
      .html_safe
  end

  def big_select_field_data(subtype, data, options = nil)
    subtype ||= 'big_select_default'
    options ||= {}

    predata = data&.transform_keys { |v| v.to_s.split(' >>>').first }
    <<~END_HTML
      <script>
        var big_select_field = $('##{big_select_field_id}')[0]
        big_select_field.big_select_options = big_select_field.big_select_options || #{options.to_json.html_safe};
        big_select_field.big_select_hash = big_select_field.big_select_hash || {};
        big_select_field.big_select_hash['#{subtype}'] = #{predata.to_json.html_safe};
      </script>
    END_HTML
      .html_safe
  end

  def big_select_field_id
    @big_select_field_id ||= "bs-field-#{SecureRandom.hex(10)}"
  end

  #
  # Convert Rails style select options to big select options list
  # @param [Hash | Array] reslist
  # @param [true] group_split - has the data been grouped using a group split character?
  # @return [Array{Hash}]
  def big_select_list_from_options(reslist, group_split = nil)
    if group_split
      reslist.transform_values! do |v|
        next unless v

        v.map { |r| [r[1], r[0]] }.to_h
      end
    else
      reslist = reslist.map { |r| [r[1], r[0]] }.to_h
    end
    reslist
  end
end
