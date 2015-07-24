class PlayerContactsController < ApplicationController
  
  include MasterHandler

  private

    def secure_params
      params.require(:player_contact).permit(:master_id, :data, :rec_type, :source, :rank)
    end
end
