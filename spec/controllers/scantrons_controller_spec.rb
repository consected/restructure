require 'rails_helper'
RSpec.describe ScantronsController, type: :controller do

  include ScantronSupport
  
  def object_class
    Scantron
  end
 
  def item
    @scantron
  end
 
  it_behaves_like 'a standard user controller'
  
end
