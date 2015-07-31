require 'rails_helper'
RSpec.describe PlayerInfosController, type: :controller do

  include PlayerInfoSupport
  def object_class
    PlayerInfo
  end
  
  def item
    @player_info
  end
  
  it_behaves_like 'a standard user controller'
  
end
