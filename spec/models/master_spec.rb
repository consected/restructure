require 'rails_helper'

RSpec.describe Master, type: :model do
  include ModelSupport
  
  before(:each) do
    seed_database
    create_user
    @master = Master.create
    
    @master.current_user = @user
    
    
  end
  
  it "should create a master successfully" do        
    expect(@master).to be_a Master
    expect(@master.id).to_not be nil
  end
  
  
  it "should support simple search across player and pro info tables" do
    
    params = {general_infos_attributes: {'0'=> {first_name: 'phil'}}}
    Master.simple_search_on_params
  end
  
 
  
end
