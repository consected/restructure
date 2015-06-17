class ProInfosController < ApplicationController
    include MasterHandler

  private
    
    def secure_params
      params.require(:pro_info).permit(:master_id, :user_id)
    end
end
