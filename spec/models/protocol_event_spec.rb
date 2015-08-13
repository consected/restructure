require 'rails_helper'

describe ProtocolEvent do
  include ModelSupport
  include ProtocolEventSupport  
  describe "definition" do
    before :each do
      seed_database
      create_user
      create_admin
      create_master      
      @protocol = Protocol.create! name: "QA#{rand 1000}", position: rand(10000), disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: "SP1", disabled: false, current_admin: @admin
      create_items :list_valid_attribs
      
      @protocol = Protocol.create! name: "QB#{rand 1000}", position: rand(10000), disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: "SP2", disabled: false, current_admin: @admin
      @sub_process = @protocol.sub_processes.create! name: "SP3", disabled: false, current_admin: @admin
      create_items :list_valid_attribs
    end
    
    it "allows multiple Protocol Events to be created and returned in order based on updated_at" do
      
      
      expect(@created_count).to eq @list.length
      
      ProtocolEvent.all.each do |p|
        
        p.current_admin = @admin
        p.save!
      end
      
      prev_pos = DateTime.now - 1.year
      ProtocolEvent.all.each do |p|                      
        expect(p.updated_at).to be <= prev_pos
        prev_pos  = p.updated_at if p.updated_at
      end
      
      expect(prev_pos).to be > DateTime.now - 1.year
      
    end
    
    it "can return active items only" do
      pa = ProtocolEvent.active
      expect(pa.length).to be > 0
      res = pa.select {|p| p.disabled }
      expect(res.length).to eq 0
    end
    
    it "can only have name updated by an admin" do
      pa = ProtocolEvent.active.first
      pa.name = "new name by me"
      
      expect(pa.save).to be false
      
      pa.current_admin = @admin
      expect(pa.save).to be true
      
      pa.reload
      expect(pa.name).to eq "new name by me"
    end
    
    it "belongs to a protocol" do 
      pa = @sub_process.protocol_events.active
      
      expect(pa.length).to be < ProtocolEvent.all.length
      
      
      
    end
  end
  

end
