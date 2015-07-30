class AddressesController < ApplicationController
  include MasterHandler
  
  def edit
    # Force the state and country codes to uppercase to allow the edit selectors to work as expected
    object_instance.state = object_instance.state.upcase if object_instance.state
    object_instance.country = object_instance.country.upcase if object_instance.country
    render partial: 'edit_form'
  end

  
  private
    
    def secure_params
      params.require(:address).permit(:master_id, :street, :street2, :street3, :city, :state, :zip, :source, :rank, :rec_type, :country, :region, :postal_code)
    end
end
