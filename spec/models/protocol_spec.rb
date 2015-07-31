require 'rails_helper'

RSpec.describe Protocol, type: :model do
  include ModelSupport
  include ProtocolSupport  
  describe "definition" do
    before :each do
      seed_database
      create_user
      create_master      
      create_items :list_valid_attribs
    end
    
    it "allows multiple Protocols to be created and returned in order based on position" do
      
      
      expect(@created_count).to eq @list.length
      
      Protocol.all.each do |p|
        p.position = rand 100
        p.save
      end
      
      prev_pos = -1
      Protocol.all.each do |p|              
        expect(p.position).to be >= prev_pos        
        prev_pos  = p.position
      end
      
      expect(prev_pos).to be > 0
      
    end
    
    it "can return active items only" do
      pa = Protocol.active
      expect(pa.length).to be > 0
      res = pa.select {|p| p.disabled }
      expect(res.length).to eq 0
    end
    
  end
end
