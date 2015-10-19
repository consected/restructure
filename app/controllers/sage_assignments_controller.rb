class SageAssignmentsController < ApplicationController
  
  include MasterHandler
  
  private
    
    def secure_params
      params.require(:sage_assignment).permit(:master_id)
    end
end
