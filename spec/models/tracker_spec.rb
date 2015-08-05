require 'rails_helper'

RSpec.describe Tracker, type: :model do
  include ModelSupport
  before(:each) do
    
    create_user
    create_admin
    @p1 = Protocol.create name: 'P1', admin: @admin
    @p2 = Protocol.create name: 'P2', admin: @admin
    
    @sp1_1 = @p1.sub_processes.create name: 'SP1', admin: @admin
    @sp1_2 = @p1.sub_processes.create name: 'SP12', admin: @admin
    @sp2_1 = @p2.sub_processes.create name: 'SP2', admin: @admin
        
    @master = Master.new    
    @master.current_user = @user
    @master.save!
    
    @tracker = @master.trackers.create protocol_id: @p1.id, sub_process_id: @sp1_1.id
  end
  
  
  it "allows trackers to be created for a master" do
    new_tracker = @master.trackers.create protocol_id: @p1.id, sub_process_id: @sp1_1.id
    expect(new_tracker.save).to be true
  end
  
  it "prevents trackers to be created outside of a master" do
    new_tracker = Tracker.create protocol_id: @p1.id, sub_process_id: @sp1_1.id, user_id: @user.id
    expect(new_tracker.save).to be false
  end
  
  it "allows sub process changes after creation" do    
    @tracker.sub_process = @sp1_2
   
    expect(@tracker.save!).to be true
  end
  
  it "prevents protocol change after creation" do
    
    @tracker.protocol = @p2
    
    @tracker.sub_process = @sp2_1
    
    expect(@tracker.save).to be false
  end
  

end
