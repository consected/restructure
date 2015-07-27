require 'rails_helper'

RSpec.describe ProInfo, type: :model do
  include ModelSupport
  
  before(:each) do
    seed_database
    create_user
    @master = Master.create
    
    @master.current_user = @user
    @pro_info = @master.pro_infos.build first_name: 'phil', last_name: 'good', middle_name: 'andrew', nick_name: 'mitch'
    
    @pro_info.save!
    
  end
  
  it "should create a pro info for testing" do

    expect(@pro_info).to be_a ProInfo
    expect(@pro_info.id).to_not be nil
  end
  
  it "should prevent changes" do
    res = @pro_info.update first_name: "charles"
    
    expect(res).to be false
    
    @pro_info.reload
    
    expect(@pro_info.first_name).to eq 'phil'
    
  end
  
end
