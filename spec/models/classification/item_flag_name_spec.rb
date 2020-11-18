require 'rails_helper'

RSpec.describe Classification::ItemFlagName, type: :model do
  
  include ModelSupport
  include ItemFlagNameSupport  
  describe "definition" do
    before :each do
      seed_database
      create_user
      create_admin
      create_master      
      create_items :list_valid_attribs
    end
    
    it "allows multiple Classification::ItemFlagName records to be created" do
      
      
      expect(@created_count).to eq @list.length
            
      Classification::ItemFlagName.all.each do |p|                      
        expect(p.name).not_to be_nil 
        
      end
      
    end
    
    it "can return active items only" do
      pa = Classification::ItemFlagName.active
      expect(pa.length).to be > 0
      res = pa.select {|p| p.disabled }
      expect(res.length).to eq 0
    end
            
    it "can only have name updated by an admin" do
      pa = Classification::ItemFlagName.active.first
      pa.name = "new name by me"
      
      expect(pa.save).to be false
      
      pa.current_admin = @admin
      expect(pa.save).to be true
      
      pa.reload
      expect(pa.name).to eq "new name by me"
    end
    
  end

  
end
