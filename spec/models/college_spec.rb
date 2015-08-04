require 'rails_helper'

RSpec.describe College, type: :model do
  include ModelSupport
  include CollegeSupport
  
  
  describe "College accessed by user" do
    
    before :each do
      seed_database
      create_user
      create_master      
    end
    
    it "should create a new college if it doesn't exist" do
      res = College.create_if_new("new college", @user)
      
      expect(res).to be_a College
      expect(res.user_id).to eq @user.id
      
    end
    it "should not create a new college if it exists" do
      
      c = College.order(id: :desc).limit(1).first
      cname = "new college #{c.id+1}"
      puts "trying college #{cname}"
      prev = College.create_if_new(cname, @user)
      expect(prev).to be_a College
      expect(prev.id).not_to be nil
      
      res = College.create_if_new(cname, @user)
      
      expect(res).to be_nil      
    end
    
    it "automatically creates a college if a player info record is created with a new college" do
      
      c = College.order(id: :desc).first
      
      pi_college = "new college #{c.id+2}"
      puts "trying college #{pi_college}"
      pi = @master.player_infos.create! first_name: "bob", rank: 881, college: pi_college
      
      expect(pi).to be_a PlayerInfo
      expect(pi.college).to eq pi_college
      
      c = College.find_by_name pi_college
      expect(c).to be_a College
      expect(College.exists? pi_college).to be true
      expect(c.user_id).to eq @user.id
      
      
      expect(College.all).to include c
    end
    
  end
end
