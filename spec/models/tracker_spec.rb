require 'rails_helper'

RSpec.describe Tracker, type: :model do
  include ModelSupport
  before(:each) do
    
    create_user
    create_admin
    @p1 = Protocol.create name: 'P1', current_admin: @admin
    @p2 = Protocol.create name: 'P2', current_admin: @admin
    
    @sp1_1 = @p1.sub_processes.create name: 'SP1', current_admin: @admin
    @sp1_2 = @p1.sub_processes.create name: 'SP12', current_admin: @admin
    @sp2_1 = @p2.sub_processes.create name: 'SP2', current_admin: @admin
        
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
    
    expect{
      Tracker.create protocol_id: @p1.id, sub_process_id: @sp1_1.id, user: @user
    }.to raise_error "can not set user="
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
  
  it "updates existing tracker record if attempting to insert with same protocol" do
    
    t2 = @master.trackers.build
    t2.protocol_id = @tracker.protocol_id
    t2.sub_process_id = @tracker.sub_process_id
    
    # Create an event to test with
    ev = @tracker.sub_process.protocol_events.create! name: "event 1", current_admin: @admin
    
    expect(ev).to be_a ProtocolEvent
    expect(ev).to be_persisted
    
    t2.protocol_event_id = ev.id
    t2.event_date = DateTime.now
    
    tres = t2.merge_if_exists
    
    expect(tres.merge_if_exists).to be_a(Tracker), "Tracker duplicate didn't save: #{t2.errors.inspect}"
    expect(tres._merged).to be true
    expect(tres.id).to eq @tracker.id
    
  end
  
end
