class PlayerContactsController < ApplicationController
  
  include MasterHandler

  private

    def secure_params
      params.require(:player_contact).permit(:master_id, :data, :pcdata, :source, :rank, :pcdate, :active)
    end
end
