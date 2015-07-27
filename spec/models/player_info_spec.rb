require 'rails_helper'

RSpec.describe PlayerInfo, type: :model do
  include ModelSupport
  
  before(:each) do
    seed_database
    create_user
    @master = Master.create
    
    @master.current_user = @user
    @player_info = @master.player_infos.build first_name: 'phil', last_name: 'good', middle_name: 'andrew', nick_name: 'mitch'
    
    @player_info.save!
    
  end
  
  it "should create a pro info for testing" do

    expect(@player_info).to be_a PlayerInfo
    expect(@player_info.id).to_not be nil
  end
  
  it "should allow changes" do
    res = @player_info.update first_name: "charles"    
    expect(res).to be true
    
    @player_info.reload    
    expect(@player_info.first_name).to eq 'charles'
    
  end
  
  
  
end
