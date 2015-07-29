require 'rails_helper'

RSpec.describe PlayerInfo, type: :model do
  include ModelSupport
  include PlayerInfoSupport
  before(:each) do
    seed_database
    create_user
    @master = Master.create
    
    @master.current_user = @user
    
    @created_count = 0
    
    list_valid_attribs.each do |v|
      @master.player_infos.create! v
      @created_count += 1
    end
    
    @player_info = @master.player_infos.build first_name: 'phil', last_name: 'good', middle_name: 'andrew', nick_name: 'mitch', birth_date: Time.now-60.years
    @created_count += 1
    @player_info.save!
    
  end
  
  it "should create a pro info for testing" do

    expect(@player_info).to be_a PlayerInfo
    expect(@player_info.id).to_not be nil
    expect(@master.player_infos.length).to eq(@created_count)
    
  end
  
  it "should allow changes to player info attributes" do
    res = @player_info.update first_name: "charles"    
    expect(res).to be true
    
    @player_info.reload    
    expect(@player_info.first_name).to eq 'charles'
    
  end
  
  it "checks whether birth date is before today" do
    
    @player_info.birth_date = DateTime.now + 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"birth date"), "Errors should contain birth date: #{@player_info.errors.inspect}"
    
  end
  
  it "checks whether death date is before today" do
    
    @player_info.death_date = DateTime.now + 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"death date"), "Errors should contain death date: #{@player_info.errors.inspect}"
    
  end
  
  it "checks whether death date is before birth date" do
    @player_info.birth_date = DateTime.now - 10.years
    @player_info.death_date = @player_info.birth_date - 1.day
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"birth and death dates"), "Errors should contain dates: #{@player_info.errors.inspect}"
    
  end
  
  it "checks whether start year is after this year" do
    @player_info.start_year = Time.now.year + 2
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"
  end
  
  it "checks whether start year is at least 19 years after and less than 30 years after birth date" do
    @player_info.birth_date = Time.now - 50.years
    @player_info.start_year = @player_info.birth_date.year + 19
    expect(@player_info.save).to be true
    @player_info.start_year = @player_info.birth_date.year + 29
    expect(@player_info.save).to be true
    
    @player_info.start_year = @player_info.birth_date.year + 30
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"
    
    @player_info.start_year = @player_info.birth_date.year + 18
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start year"), "Errors should contain start year: #{@player_info.errors.inspect}"
  end
  
  it "checks whether end year is after this year" do
    @player_info.end_year = Time.now.year + 2
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"end year"), "Errors should contain end year: #{@player_info.errors.inspect}"
    
  end
  
  it "checks whether end year is before start year" do
    @player_info.start_year = Time.now.year - 20
    @player_info.end_year = @player_info.start_year - 1
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"start and end years"), "Errors should contain years: #{@player_info.errors.inspect}"
    
  end
  
  it "presents an error if the birth_date is not set and the rank is not set to 881" do
    orig = Time.now - 60.years
    @player_info.birth_date = nil
    @player_info.rank = 881
    expect(@player_info.save).to be true
    
    @player_info.rank = 888
    expect(@player_info.save).to be false
    expect(@player_info.errors.messages).to have_key(:"birth date")
    
    @player_info.birth_date = orig
    expect(@player_info.save).to be true
    
    
  end
  
end
