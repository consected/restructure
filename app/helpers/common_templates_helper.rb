# frozen_string_literal: true

module CommonTemplatesHelper
  def handle_set_related_field(object_instance, field_name)
    object_instance.set_related_fields[field_name] if object_instance.respond_to?(:set_related_fields)
  end

  def zip_field_props(init = {})
    init.merge({ pattern: '\\d{5,5}(-\\d{4,4})?' })
  end

  #
  # Field options for the field, from the dynamic configuration.
  # Use reset: true to clear the memo, which speeds up some large forms
  # @return [Hash]
  def field_options_for(form_object_instance, field_name_sym, reset: nil)
    @field_options_for = nil if reset
    return @field_options_for if @field_options_for

    if form_object_instance.respond_to?(:option_type_config) && form_object_instance.option_type_config
      fopt = form_object_instance.option_type_config.field_options[field_name_sym].dup
    end

    fopt ||= {}

    if fopt[:value]
      fres = form_object_instance.attributes[field_name_sym.to_s]
      if !form_object_instance.persisted? && fres.blank?
        fres = fopt[:value]
        fres = FieldDefaults.calculate_default form_object_instance, fres
      end

      fopt[:selected] = fres
      fopt[:value] = fres
    end

    @field_options_for = fopt
  end

  def general_selection_prefix_name(form_object_instance)
    Classification::GeneralSelection.prefix_name form_object_instance
  end

  def general_selection_source_name(form_object_instance)
    "#{general_selection_prefix_name(form_object_instance)}_source"
  end
end
