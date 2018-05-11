class ExternalIdentifier::ExternalIdentifierController < UserBaseController

  include MasterHandler

  protected
    # By default the external id edit form is handled through a common template. To provide a customized form, copy the content of
    # "common_templates/external_id_edit_form.html.erb" to views/<name>/_edit_form.html.erb
    def edit_form
      'common_templates/external_id_edit_form'
    end


  private

    def secure_params
      defn = implementation_class.definition
      res = params.require(controller_name.singularize.to_sym).permit(:master_id, defn.external_id_attribute.to_sym)
      # Extra protection to avoid possible injection of an alternative value
      # when we should be using a generated ID
      res[implementation_class.external_id_attribute.to_sym] = nil if implementation_class.allow_to_generate_ids?
      res
    end



end
