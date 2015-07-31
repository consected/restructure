require 'rails_helper'

RSpec.describe AddressesController, type: :controller do

  include AddressSupport
  
  def item
    @address
  end
  
  def object_class
    Address
  end  
  
  it_behaves_like 'a standard user controller'
  

end
