require 'rails_helper'

# Testing user authentication
RSpec.describe MastersController, :type => :controller do   
  include Devise::TestHelpers   
  include Warden::Test::Helpers   
  
  before_each_login_user
  
  it "sign in through Devise user" do      
    get :new
    expect(response).to_not redirect_to 'http://test.host/users/sign_in'
  end
end

