class AddressesController < ApplicationController
  include MasterHandler
  
  private
    
    def secure_params
      params.require(:address).permit(:master_id, :street, :street2, :street3, :city, :state, :zip, :source, :rank, :rec_type, :country, :region, :postal_code)
    end
end
