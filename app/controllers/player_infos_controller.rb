class PlayerInfosController < ApplicationController
  include MasterHandler

  protected
    def edit_form
      'common_templates/edit_form'
    end
   
    def permitted_params
      [:master_id, :first_name, :last_name, :middle_name, :nick_name, :birth_date, :death_date, :start_year, :end_year, :college, :source, :rank, :notes]
    end
  private
    
    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end
end
