require 'rails_helper'
RSpec.describe PlayerContactsController, type: :controller do

  include PlayerContactSupport
  ObjectClass = PlayerContact
  def item
    @player_contact
  end
  
  ObjectsSymbol = ObjectClass.to_s.underscore.pluralize.to_sym
  
  ObjectSymbol = ObjectClass.to_s.underscore.to_sym
  
  def item_id
    item.to_param
  end
  
  def edit_form
    "#{ObjectsSymbol}/_edit_form"
  end
  
  it_behaves_like 'a standard user controller'
  
end
