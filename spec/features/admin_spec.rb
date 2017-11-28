require 'rails_helper'

describe "admin sign in process", driver: :app_firefox_driver do

  include ModelSupport

  before(:all) do
    @good_email = "testuser#{rand(1000000000)}admin@testing.com"

    @admin = Admin.create email: @good_email
    @good_password = @admin.new_password
    ENV['FPHS_ADMIN_SETUP']='yes'

    #create an admin that has been disabled
    @d_email = "testuserdis#{rand(1000000000)}admin@testing.com"


    @d_admin = Admin.create email: @d_email
    @d_pw = @d_admin.new_password

    expect(@d_admin).to be_persisted
    expect(@d_admin.active_for_authentication?).to be true
    expect(@d_admin.disable!).to be true

    @d_admin.reload
    expect(@d_admin.disabled).to be true
    expect(@d_admin.active_for_authentication?).to be false


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

    expect(page).to have_css "input:invalid"

    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password + ' '
      click_button "Log in"
    end

    fail_message = "× Invalid Email or password."

    expect(page).to have_css ".flash .alert", text: fail_message

    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: ' '+@good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: fail_message


    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end

  it "should prevent sign in if admin disabled" do



    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @d_email
      fill_in "Password", with: @d_pw
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× This account has been disabled."

  end


  after(:all) do
    #@admin.destroy!
  end
end
