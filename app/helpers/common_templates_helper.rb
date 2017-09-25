module CommonTemplatesHelper

  def handle_set_related_field(field_name)
    if object_instance.respond_to?(:set_related_fields_edit)
      object_instance.set_related_fields_edit[field_name]
    end
  end

end