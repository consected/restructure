class ScantronsController < ApplicationController
  
  include MasterHandler
  
  private
    
    def secure_params
      params.require(:scantron).permit(:master_id, :scantron_id, :source, :rank, :user_id)
    end
end
