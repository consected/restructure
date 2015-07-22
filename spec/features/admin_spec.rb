require 'rails_helper'

describe "admin sign in process" do
  before(:all) do
    @good_email = "testuser#{rand(1000000000)}admin@testing.com"
    @good_password = Devise.friendly_token.first(12)
    @admin = Admin.create email: @good_email, password: @good_password
    @good_password = @admin.password
    
  end

  it "should sign in" do
    
    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id
    
    #login_as @user, scope: :user
    
    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end
  
  it "should prevent invalid sign in" do
    
    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id
    
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
    @admin.destroy!
  end
end
