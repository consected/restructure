class SageAssignmentsController < ApplicationController
  
  include MasterHandler
  
  private
    
    def secure_params
      res = params.require(:sage_assignment).permit(:master_id, :sage_id)
      res[:sage_id] = nil
      res
    end
end
