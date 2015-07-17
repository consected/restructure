require 'rails_helper'

describe User do
  before(:each) do
    @good_email = 'testuser-model@testing.com'
    @good_password = Devise.friendly_token.first(12)
    @user = User.create email: @good_email, password: @good_password  
  end

  it "creates a user" do
    new_user = User.where email: @good_email
    expect(new_user.first).to be_a User
  end
  
end

