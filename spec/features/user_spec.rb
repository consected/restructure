require 'rails_helper'

describe "user sign in process" do
  
  include ModelSupport
  
  before(:all) do
    
     
    @user, @good_password  = create_user
    @good_email  = @user.email
    
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
  
  it "should prevent sign in if user disabled" do
    
    user, pw = create_user(rand(1000000000)+100000000)
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    create_admin
    user.current_admin = @admin
    user.disabled = true
    user.save!
    expect(user.active_for_authentication?).to be false
    
    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: user.email
      fill_in "Password", with: pw
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× This account has been disabled."

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
    
  end
end

