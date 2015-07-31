require 'rails_helper'
RSpec.describe PlayerContactsController, type: :controller do

  include PlayerContactSupport
  def object_class
    PlayerContact
  end
  
  def item
    @player_contact
  end
 
  
  it_behaves_like 'a standard user controller'
  
end
