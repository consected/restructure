require 'rails_helper'

RSpec.describe UserAuthorization, type: :model do
  
  include ModelSupport
  
  
  it "should prevent a user from having multiple entries for the same authorization" do
    
    create_user
    
    res = UserAuthorization.create! user: @user, has_authorization: :create_msid, current_admin: @admin
    
    
    expect{
      UserAuthorization.create! user: @user, has_authorization: :create_msid, current_admin: @admin
    }.to raise_error ActiveRecord::RecordInvalid
    
  end
end
