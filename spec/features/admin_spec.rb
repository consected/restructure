# frozen_string_literal: true

require 'rails_helper'

describe 'admin sign in process', driver: :app_firefox_driver do
  include ModelSupport

  def make_an_admin
    ENV['FPHS_ADMIN_SETUP'] = 'yes'

    @good_email = "testuser#{rand(1_000_000_000)}admin@testing.com"
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
    SetupHelper.feature_setup

    ENV['FPHS_ADMIN_SETUP'] = 'yes'

    Admin.transaction do
      # create an admin that has been disabled
      @d_email = "testuserdis#{rand(1_000_000_000)}admin@testing.com"

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

      @final_good_email = "test-final#{rand(1_000_000_000)}admin@testing.com"
      @final_admin = Admin.create! email: @final_good_email

      @final_admin = Admin.find(@final_admin.id)
      @final_good_password = @final_admin.generate_password
      @final_admin.otp_secret = Admin.generate_otp_secret
      @final_admin.otp_required_for_login = true
      @final_admin.new_two_factor_auth_code = false
      @final_admin.save!
      @final_admin = Admin.find(@final_admin.id)
    end
  end

  it "won't show the admin page unless using a secure URL param" do
    visit '/admins/sign_in'
    expect(current_path).to eq '/users/sign_in'
  end

  it 'should sign in' do
    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    visit url
    expect(current_path).to eq '/admins/sign_in'

    within '#new_admin' do
      expect(@admin.email).to eq @good_email
      expect(@admin.valid_password?(@good_password)).to be true
      # Do not validate, since this consumes the one time code and prevents it from being used (causes a long delay in the process)
      # expect(@admin.validate_one_time_code(@admin.current_otp)).to be true

      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.")
  end

  it 'should sign in with 2FA even if it is disabled for users' do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', false)
    expect(User.two_factor_auth_disabled).to be true
    expect(Admin.two_factor_auth_disabled).to be false

    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    visit url
    expect(current_path).to eq '/admins/sign_in'

    within '#new_admin' do
      expect(@admin.email).to eq @good_email
      expect(@admin.valid_password?(@good_password)).to be true
      # Do not validate, since this consumes the one time code and prevents it from being used (causes a long delay in the process)
      # expect(@admin.validate_one_time_code(@admin.current_otp)).to be true

      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.")
  end

  it 'should prevent invalid sign in' do
    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    # login_as @user, scope: :user

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: ''
      click_button 'Log in'
    end

    expect(page).to have_css 'input:invalid'

    # make a new admin to avoid lockout
    # make_an_admin

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password + ' '
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    fail_message = "×\nInvalid email, password or two-factor authentication code."

    expect(page).to have_css '.flash .alert', text: fail_message

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @final_good_email
      fill_in 'Password', with: ' ' + @final_good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @final_admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: fail_message

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"

    # Wait until the next otp becomes valid
    sleep 31
    just_signed_in = false

    # visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @final_good_email
      fill_in 'Password', with: @final_good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @final_admin.current_otp
      click_button 'Log in'
    end

    have_css '.flash .alert'

    fa = all('.flash .alert')[0]
    if fa
      just_signed_in = (fa.text == "×\nSigned in successfully.")
      puts fa.text unless just_signed_in
    end

    expect(just_signed_in).to be true
  end

  it 'should prevent sign in if admin disabled' do
    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @d_email
      fill_in 'Password', with: @d_pw
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @d_admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert'
  end

  after(:all) do
    # @admin.destroy!
  end
end
