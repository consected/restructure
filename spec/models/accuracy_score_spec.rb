require 'rails_helper'

RSpec.describe AccuracyScore, type: :model do
  
  include ModelSupport
  include AccuracyScoreSupport  
  describe "definition" do
    before :each do
      seed_database
      create_user
      create_admin
      create_master      
      create_items :list_valid_attribs
    end
    
    it "allows multiple AccuracyScore records to be created" do
      
      
      expect(@created_count).to eq @list.length
            
      AccuracyScore.all.each do |p|                      
        expect(p.name).not_to be_nil 
        expect(p.value).not_to be_nil
      end
      
    end
    
    it "can return active items only" do
      pa = AccuracyScore.active
      expect(pa.length).to be > 0
      res = pa.select {|p| p.disabled }
      expect(res.length).to eq 0
    end
    
    it "can not have value changed" do
      pa = AccuracyScore.active.first
      pa.current_admin = @admin
      pa.value = 'a new value for value'
      expect(pa.save).to be false
    end
        
    it "can only have name updated by an admin" do
      pa = AccuracyScore.active.first
      pa.name = "new name by me"
      
      expect(pa.save).to be false
      
      pa.current_admin = @admin
      expect(pa.save).to be true
      
      pa.reload
      expect(pa.name).to eq "new name by me"
    end
    
  end
end
