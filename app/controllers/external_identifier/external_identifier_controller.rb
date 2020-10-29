# frozen_string_literal: true

class ExternalIdentifier::ExternalIdentifierController < UserBaseController
  include MasterHandler

  def template_config
    render plain: ''
  end

  protected

  # By default the external id edit form is handled through a common template.
  def edit_form
    'common_templates/edit_form'
  end

  private

  def secure_params
    defn = implementation_class.definition
    field_list = [:master_id] + defn.field_list_array

    res = params.require(controller_name.singularize.to_sym).permit(field_list)
    # Extra protection to avoid possible injection of an alternative value
    # when we should be using a generated ID
    res[implementation_class.external_id_attribute.to_sym] = nil if implementation_class.allow_to_generate_ids?
    res
  end
end
