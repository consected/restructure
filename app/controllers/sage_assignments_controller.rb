class SageAssignmentsController < ApplicationController
  
  include MasterHandler

  protected
    # By default the external id edit form is handled through a common template. To provide a customized form, copy the content of
    # "common_templates/external_id_edit_form.html.erb" to views/sage_assignments/_edit_form.html.erb
    def edit_form
      'common_templates/external_id_edit_form'
    end
  
  private
    
    def secure_params
      res = params.require(:sage_assignment).permit(:master_id, :sage_id)
      res[:sage_id] = nil
      res
    end
end
