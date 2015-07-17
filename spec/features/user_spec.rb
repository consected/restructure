require 'rails_helper'

describe "user sign in process" do
  before(:all) do
    @good_email = 'testuser@testing.com'
    @good_password = Devise.friendly_token.first(12)
    @user = User.create email: @good_email
    @good_password = @user.password
    
  end

  it "should sign in" do
    
    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    #login_as @user, scope: :user
    
    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end
#    visit "/masters/search/"
    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"
 #   expect(page).to have_content "First or nick name"
  end
  
  
  after(:all) do
    @user.destroy!
  end
end

