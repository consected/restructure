require 'rails_helper'

RSpec.describe AddressesController, type: :controller do
  include AddressSupport

  def item
    @address
  end

  def object_class
    Address
  end

  def edit_form_prefix
    @edit_form_prefix = 'common_templates'
  end

  it_behaves_like 'a standard user controller'
end
