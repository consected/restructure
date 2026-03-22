# frozen_string_literal: true

class ExternalIdentifier::ExternalIdentifierController < UserBaseController
  include MasterHandler

  def template_config
    Application.refresh_dynamic_defs

    render plain: ''
  end

  protected

  #
  # By default the external id edit form is handled through a common template.
  def edit_form
    'common_templates/edit_form'
  end

  private

  #
  # Get the values from request params as secure (strong) params
  # Perform additional processing to provide
  # extra protection to avoid possible injection of an alternative value
  # when we should be using a generated ID.
  def secure_params
    return @secure_params if @secure_params

    defn = implementation_class.definition
    field_list = [:master_id] + defn.field_list_array

    res = params.require(controller_name.singularize.to_sym).permit(field_list)
    attr_ext_id = implementation_class.external_id_attribute
    attr_ext_id_val = res[attr_ext_id.to_sym]
    if implementation_class.allow_to_generate_ids? && object_instance.id && object_instance[attr_ext_id].to_s != attr_ext_id_val.to_s
      res[attr_ext_id] = nil
    end
    @secure_params = res
  end

  #
  # Remove items that are not showable, based on showable_if in the options config
  def filter_records
    return unless @master_objects
    return @master_objects if @master_objects.is_a? Array

    @filtered_ids = @master_objects
                    .select { |i| i.option_type_config&.calc_if(:showable_if, i) }
                    .map(&:id)
    @master_objects = @master_objects.where(id: @filtered_ids)
    filter_requested_ids
    limit_results
  end
end
