class ScantronsController < ApplicationController
  
  include MasterHandler
  
  private
    
    def secure_params
      params.require(:scantron).permit(:master_id, :scantron_id)
    end
end
