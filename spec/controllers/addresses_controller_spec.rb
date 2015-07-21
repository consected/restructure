require 'rails_helper'

RSpec.describe AddressesController, type: :controller do

  include AddressSupport
  ObjectClass = Address
  def item
    @address
  end
  
  
  
  ObjectsSymbol = ObjectClass.to_s.underscore.pluralize.to_sym
  ObjectSymbol = ObjectClass.to_s.underscore
  
  def item_id
    item.to_param
  end
  
  def edit_form
    "#{ObjectsSymbol}/_edit_form"
  end
  
  
  it_behaves_like 'a standard user controller'
  

end
