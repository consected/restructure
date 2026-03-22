module DynamicModelExpectationsSupport
  def expect_block(block = nil)
    block ||= page
    expect(block)
  end

  def dm_form_mode(mode)
    @dm_form_mode = mode
  end

  def new_form_css(resource_name = nil)
    resource_name ||= @resource_name
    "form.new_#{resource_name.to_s.singularize.gsub('__', '_')}"
  end

  def edit_form_css(resource_name = nil)
    resource_name ||= @resource_name
    "form.edit_#{resource_name.to_s.singularize.gsub('__', '_')}"
  end

  def show_form_css(resource_name = nil)
    resource_name ||= @resource_name
    ".common-templates--result-item[data-item-class=\"#{resource_name.to_s.singularize}\"]"
  end

  def have_caption_before(field_name, caption = nil, mode: nil)
    mode ||= @dm_form_mode
    data_attr_name = mode.in?(%i[edit new]) ? 'data-cb-field-name' : 'data-cb-field-name'
    extra_args = caption.nil? ? {} : { text: caption }
    have_css("[#{data_attr_name}='#{field_name}']", **extra_args)
  end

  def have_field_label(field_name, label_text = nil, mode: nil)
    mode ||= @dm_form_mode
    if mode.in?(%i[edit new])
      data_attr_name = 'data-edit-field-name'
      tagname = 'label'
    else
      data_attr_name = 'data-field-name'
      tagname = 'small.ctlabel'
    end
    extra_args = label_text.nil? ? {} : { text: label_text }
    have_css("[#{data_attr_name}='#{field_name}'] #{tagname}", **extra_args)
  end

  def have_input_field(field_name, tagname: 'input', mode: nil, value: nil)
    mode ||= @dm_form_mode
    if mode.in?(%i[edit new])
      data_attr_name = 'data-attr-name'
    else
      data_attr_name = 'data-field-name'
      tagname = 'li.result-field-container'
    end

    css = "#{tagname}[#{data_attr_name}='#{field_name}']"
    res = have_css(css)
    if value
      res = if mode.in?(%i[edit new])
              find(css).value == value
            else
              have_css(css, text: value)
            end
    end
    res
  end

  def have_show_form(resource_name = nil, option_type: nil)
    resource_name ||= @resource_name
    res = have_css(show_form_css(resource_name))
    if option_type
      res = have_css("#{show_form_css(resource_name)} .common-template-item-inner[data-option-type-config-name='#{option_type}']")
    end
    res
  end

  def have_edit_form(resource_name = nil, option_type: nil)
    resource_name ||= @resource_name
    res = have_css(edit_form_css(resource_name))
    res = have_css("#{edit_form_css(resource_name)}[data-option-type-config-name='#{option_type}']") if option_type
    res
  end

  def have_new_form(resource_name = nil, option_type: nil)
    resource_name ||= @resource_name
    res = have_css(new_form_css(resource_name))
    res = have_css("#{new_form_css(resource_name)}[data-option-type-config-name='#{option_type}']") if option_type
    res
  end

  def click_edit_button_in(css)
    find(css).find('a.edit-entity').click
  end
end
