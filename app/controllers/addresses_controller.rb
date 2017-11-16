class AddressesController < ApplicationController
  include MasterHandler

  def edit
    # Force the state and country codes to uppercase to allow the edit selectors to work as expected
    object_instance.state = object_instance.state.upcase if object_instance.state
    object_instance.country = object_instance.country.upcase if object_instance.country

    super
  end

  protected
    def edit_form
      'common_templates/edit_form'
    end

    def permitted_params
      [:master_id,:country,  :street, :street2, :street3, :city, :state, :zip, :region, :postal_code, :source, :rank, :rec_type]
    end
  private

    def secure_params
      params.require(object_name.to_sym).permit(*permitted_params)
    end
end
