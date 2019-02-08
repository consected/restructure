require 'rails_helper'

describe "admin sign in process", driver: :app_firefox_driver do

  include ModelSupport

  def make_an_admin
    ENV['FPHS_ADMIN_SETUP']='yes'

    @good_email = "testuser#{rand(1000000000)}admin@testing.com"
    @admin = Admin.create! email: @good_email
    # Save a new password, as required to handle temp passwords
    @admin = Admin.find(@admin.id)
    @good_password = @admin.generate_password
    @admin.save!
    @admin.otp_secret = Admin.generate_otp_secret
    @admin.otp_required_for_login = true
    @admin.new_two_factor_auth_code = false
    @admin.save!


    @good_password
  end

  before(:all) do
    ENV['FPHS_ADMIN_SETUP']='yes'


    @final_good_email = "test-final#{rand(1000000000)}admin@testing.com"
    @final_admin = Admin.create! email: @final_good_email

    @final_admin = Admin.find(@final_admin.id)
    @final_good_password = @final_admin.generate_password
    @final_admin.otp_secret = Admin.generate_otp_secret
    @final_admin.otp_required_for_login = true
    @final_admin.new_two_factor_auth_code = false
    @final_admin.save!



    #create an admin that has been disabled
    @d_email = "testuserdis#{rand(1000000000)}admin@testing.com"


    @d_admin = Admin.create email: @d_email

    # Save a new password, as required to handle temp passwords
    @d_admin = Admin.find(@d_admin.id)
    @d_pw = @d_admin.generate_password
    @d_admin.otp_secret = Admin.generate_otp_secret
    @d_admin.otp_required_for_login = true
    @d_admin.new_two_factor_auth_code = false
    @d_admin.save!

    expect(@d_admin).to be_persisted
    expect(@d_admin.active_for_authentication?).to be true
    expect(@d_admin.disable!).to be true

    @d_admin.reload
    expect(@d_admin.disabled).to be true
    expect(@d_admin.active_for_authentication?).to be false

    make_an_admin

  end

  it "won't show the admin page unless using a secure URL param" do
    visit "/admins/sign_in"
    expect(current_path).to eq '/users/sign_in'
  end


  it "should sign in" do

    # make_an_admin

    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id


    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      expect(@admin.email).to eq @good_email
      expect(@admin.valid_password?(@good_password)).to be true
      expect(@admin.validate_one_time_code(@admin.current_otp)).to be true

      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      fill_in "One-Time Code", with: @admin.current_otp

      click_button "Log in"
    end
    expect(page).to have_css( ".flash .alert", text: "× Signed in successfully")

  end

  it "should prevent invalid sign in" do

    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    #login_as @user, scope: :user

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: ""
      fill_in "One-Time Code", with: @admin.current_otp
      click_button "Log in"
    end

    expect(page).to have_css "input:invalid"

    # make a new admin to avoid lockout
    # make_an_admin

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password + ' '
      fill_in "One-Time Code", with: @admin.current_otp
      click_button "Log in"
    end

    fail_message = "× Invalid email, password or one-time code."

    expect(page).to have_css ".flash .alert", text: fail_message

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in "Email", with: @final_good_email
      fill_in "Password", with: ' '+@final_good_password
      fill_in "One-Time Code", with: @final_admin.current_otp
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: fail_message


    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in "Email", with: @final_good_email
      fill_in "Password", with: @final_good_password
      fill_in "One-Time Code", with: @final_admin.current_otp
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end

  it "should prevent sign in if admin disabled" do



    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in "Email", with: @d_email
      fill_in "Password", with: @d_pw
      fill_in "One-Time Code", with: @d_admin.current_otp
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert"

  end


  after(:all) do
    #@admin.destroy!
  end
end
