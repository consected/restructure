require 'rails_helper'

describe "admin sign in process" do

  include ModelSupport

  before(:all) do
    @good_email = "testuser#{rand(1000000000)}admin@testing.com"
    
    @admin = Admin.create email: @good_email
    @good_password = @admin.new_password
    
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

    
    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end
  
  it "should prevent sign in if admin disabled" do
    
    email = "testuserdis#{rand(1000000000)}admin@testing.com"
    
    @admin = Admin.create email: email
    pw = @admin.new_password
    puts "Password: #{pw} for #{email}"
    expect(@admin).to be_persisted
    expect(@admin.active_for_authentication?).to be true
    
    expect(@admin.disable!).to be true
    expect(@admin.active_for_authentication?).to be false
    
    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: email
      fill_in "Password", with: pw
      click_button "Log in"
    end
    
    expect(page).to have_css ".flash .alert", text: "× This account has been disabled."

  end
  
  
  after(:all) do
    @admin.destroy!
  end
end
