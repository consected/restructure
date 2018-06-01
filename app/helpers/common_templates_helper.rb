module CommonTemplatesHelper

  def handle_set_related_field(field_name)
    if object_instance.respond_to?(:set_related_fields)
      object_instance.set_related_fields[field_name]
    end
  end

  def zip_field_props init={}
    init.merge({pattern: "\\d{5,5}(-\\d{4,4})?"})
  end


  def field_options_for form_object_instance, field_name_sym
    if form_object_instance.option_type_config
      fopt = form_object_instance.option_type_config.field_options[field_name_sym]
    end

    fopt ||= {}
    fopt[:value] = DateTime.now.iso8601 if fopt[:value] == 'now()'
    fopt[:value] = DateTime.now.iso8601.split('T').first if fopt[:value] == 'today()'

    fopt
  end

end
