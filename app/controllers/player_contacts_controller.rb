class PlayerContactsController < ApplicationController
  
  include MasterHandler

  protected
    def edit_form
      'common_templates/edit_form'
    end
 
  
    def permitted_params
      @permitted_params = [:master_id, :rec_type, :data, :source, :rank]
    end
  private

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end
end
