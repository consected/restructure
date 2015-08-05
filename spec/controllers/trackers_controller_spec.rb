require 'rails_helper'


RSpec.describe TrackersController, type: :controller do

  include TrackerSupport
  
  def item
    @address
  end
  
  def object_class
    Tracker
  end  
  
  it_behaves_like 'a standard user controller'
  

end
