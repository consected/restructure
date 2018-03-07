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

end
