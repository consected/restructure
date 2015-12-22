class ScantronsController < ApplicationController
  
  include MasterHandler
  
  protected
    # By default the external id edit form is handled through a common template. To provide a customized form, copy the content of
    # "common_templates/external_id_edit_form.html.erb" to views/scantrons/_edit_form.html.erb
    def edit_form
      'common_templates/external_id_edit_form'
    end
  
  private
    
    def secure_params
      params.require(:scantron).permit(:master_id, :scantron_id)
    end
end
