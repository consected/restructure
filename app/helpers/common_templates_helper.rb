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

    if fopt[:value] || fopt[:blank_value]
      fres = form_object_instance.attributes[field_name_sym.to_s]
      if fres.blank?
        fres = if form_object_instance.persisted?
                 fopt[:blank_value]
               else
                 fopt[:value]
               end
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

  def class_for_open_panels(resource, default_panels_length)
    "{{# is (split_lines open_panels) 'includes' '#{resource}'}}on-open-click initial_show_value-true-{{else}}initial_show_value-false-{{/is}}#{default_panels_length}".html_safe
  end

  def def_uac_summary_data(object_instance:, current_user:, current_app_type_id:, resource_name: nil, resource_type: 'table')
    resource_name = resource_name || object_instance.resource_name&.pluralize
    return { resource_name:, resource_type:, uacs: [], no_non_template_uacs: true, current_user_has_access: false, current_app_uacs: [] } if resource_name.blank?

    uacs = Admin::UserAccessControl.active_for(resource_name:).not_template_role
    no_non_template_uacs = uacs.empty?

    current_user_has_access = false
    if current_user && current_app_type_id
      current_user_has_access = Admin::UserAccessControl.access_for?(
        current_user,
        :access,
        resource_type.to_sym,
        resource_name,
        alt_app_type_id: current_app_type_id
      ).present?
    end

    current_app_uacs = uacs.select { |uac| uac.app_type_id == current_app_type_id }

    {
      resource_name:,
      resource_type:,
      uacs:,
      no_non_template_uacs:,
      current_user_has_access:,
      current_app_uacs:
    }
  end

  def def_uac_needs_attention?(object_instance:, current_user:, current_app_type_id:, resource_name: nil, resource_type: 'table')
    uac_data = def_uac_summary_data(
      object_instance:,
      current_user:,
      current_app_type_id:,
      resource_name:,
      resource_type:
    )

    uac_data[:no_non_template_uacs] ||
      (current_app_type_id.present? && !uac_data[:current_user_has_access]) ||
      (current_app_type_id.present? && uac_data[:current_app_uacs].empty?)
  end
end
