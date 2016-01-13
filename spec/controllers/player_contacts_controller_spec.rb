require 'rails_helper'
RSpec.describe PlayerContactsController, type: :controller do

  include PlayerContactSupport
  def object_class
    PlayerContact
  end
  
  def item
    @player_contact
  end

  def edit_form_prefix
    @edit_form_prefix = "common_templates"
  end
  
  
  it_behaves_like 'a standard user controller'
  
end
