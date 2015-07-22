require 'rails_helper'

describe "user sign in process" do
  before(:all) do
    @good_email = "test#{rand 100000000}user@testing.com"
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

it "should prevent invalid sign in" do
    
    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    #login_as @user, scope: :user
    
    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: ""
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Invalid email or password."
    
    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password + ' '
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Invalid email or password."

    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: ' '+@good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Invalid email or password."

  end
    
  
  after(:all) do
    @user.destroy!
  end
end

