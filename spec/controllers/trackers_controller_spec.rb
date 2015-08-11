require 'rails_helper'


RSpec.describe TrackersController, type: :controller do

  include TrackerSupport
  
  def item
    @tracker
  end
  
  def object_class
    Tracker
  end  
  
  before :each do    
    admin, pw = ControllerMacros.create_admin    
    @admin = admin
  end
  it_behaves_like 'a standard user controller'
  

end
