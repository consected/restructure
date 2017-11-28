require 'rails_helper'

describe "user sign in process", js: true, driver: :app_firefox_driver do

  include ModelSupport

  before(:all) do




    #create a user, then disable it
    @d_user, @d_pw = create_user(rand(1000000000)+100000000)
    expect(@d_user).to be_a User
    expect(@d_user.id).to equal @user.id
    @d_email = @d_user.email
    create_admin
    @d_user.current_admin = @admin
    @d_user.disabled = true
    @d_user.save!
    expect(@d_user.active_for_authentication?).to be false

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

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end

  it "should prevent sign in if user disabled" do


    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: @d_email
      fill_in "Password", with: @d_pw
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

    fail_message = "× Invalid Email or password."

    expect(page).to have_css "input:invalid"

    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password + ' '
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: fail_message

    visit "/admins/sign_in"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: ' '+@good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: fail_message

  end


  after(:all) do

  end
end
