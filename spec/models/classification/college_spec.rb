require 'rails_helper'

RSpec.describe Classification::College, type: :model do
  include ModelSupport
  include CollegeSupport
  
  
  describe "Classification::College accessed by user" do
    
    before :each do
      seed_database
      create_user
      create_master      
    end
    
    it "should create a new college if it doesn't exist" do
      res = Classification::College.create_if_new("new college", @user)
      
      expect(res).to be_a Classification::College
      expect(res.user_id).to eq @user.id
      
    end
    
    it "should not create a new college if it exists" do
      
      cname = "new college #{DateTime.now}".downcase
      c = Classification::College.create_if_new(cname, @user)
      
      expect(c.id).not_to be_nil
      
      prev = Classification::College.create_if_new(cname + " 123", @user)
      expect(prev).to be_a Classification::College
      expect(prev.id).not_to be_nil
      
      res = Classification::College.create_if_new(cname, @user)
      
      expect(res).to be_nil      
    end
    
    it "automatically creates a college if a player info record is created with a new college" do
      
      c = Classification::College.order(id: :desc).first
      
      pi_college = "new college b #{DateTime.now}".downcase
      
      pi = @master.player_infos.create! first_name: "bob", rank: 881, college: pi_college, source: 'nflpa'
      
      expect(pi).to be_a PlayerInfo
      expect(pi.college).to eq pi_college
      
      c = Classification::College.find_by_name pi_college
      expect(c).to be_a Classification::College
      expect(Classification::College.exists? pi_college).to be true
      expect(c.user_id).to eq @user.id
      
      
      expect(Classification::College.all).to include c
    end
    
    it "should require either an admin or user to be set" do
      cname = "new college c#{DateTime.now}".downcase
      
      c = nil
      expect{
        c = Classification::College.create_if_new(cname, nil)
      }.to raise_error("bad user set")
      
      expect(c).to be_nil
      
    end
  end
end
