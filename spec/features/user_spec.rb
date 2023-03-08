# frozen_string_literal: true

require 'rails_helper'

describe 'user sign in process', js: true, driver: :app_firefox_driver do
  include ModelSupport

  context '2FA complete' do
    before(:all) do
      change_setting('AllowUsersToRegister', false)
      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!

      SetupHelper.feature_setup

      change_setting('TwoFactorAuthDisabledForUser', false)
      change_setting('TwoFactorAuthDisabledForAdmin', false)

      # create a user, then disable it
      @d_user, @d_pw = create_user(rand(100_000_000..1_099_999_999))
      expect(@d_user).to be_a User
      expect(@d_user.id).to equal @user.id
      @d_email = @d_user.email
      create_admin
      @d_user.current_admin = @admin
      @d_user.send :setup_two_factor_auth
      @d_user.new_two_factor_auth_code = false
      @d_user.otp_required_for_login = true
      @d_user.disabled = true
      @d_user.save!
      expect(@d_user.active_for_authentication?).to be false

      @user, @good_password = create_user
      @good_email = @user.email
    end

    it 'should sign in' do
      validate_setup
      expect(User.two_factor_auth_disabled).to be false

      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).to have_selector('#new_user', visible: true)
      expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: "×\nSigned in successfully."
    end

    it 'should prevent sign in if user disabled' do
      expect(User.two_factor_auth_disabled).to be false
      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @d_email
        fill_in 'Password', with: @d_pw
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).to have_selector('#new_user', visible: true)
      expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

      within '#new_user' do
        fill_in 'Two-Factor Authentication Code', with: @d_user.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: "×\nThis account has been disabled."
    end

    it 'should prevent invalid sign in' do
      expect(Admin.two_factor_auth_disabled).to be false
      validate_setup

      visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: ''
        click_button 'Log in'
      end

      expect(page).not_to have_selector('.login-2fa-block', visible: true)

      fail_message = "×\nInvalid email, password or two-factor authentication code."

      expect(page).to have_css 'input:invalid'

      visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password + ' '
        click_button 'Log in'
      end

      puts '------------>' + page.find('body')[:class] unless has_selector?('.login-2fa-block', visible: true)
      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).to have_selector('#new_admin', visible: true)
      expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

      within '#new_admin' do
        fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: fail_message

      visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
      within '#new_admin' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: ' ' + @good_password
        click_button 'Log in'
      end

      expect(page).to have_selector('.login-2fa-block', visible: true)
      expect(page).to have_selector('#new_admin', visible: true)
      expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

      within '#new_admin' do
        fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
        click_button 'Log in'
      end

      expect(page).to have_css '.flash .alert', text: fail_message
    end
  end

  context '2FA setup required' do
    before(:all) do
      change_setting('AllowUsersToRegister', false)
      Rails.application.reload_routes!
      Rails.application.routes_reloader.reload!

      SetupHelper.feature_setup

      change_setting('TwoFactorAuthDisabledForUser', false)

      # create a user, then disable it
      @d_user, @d_pw = create_user(rand(100_000_000..1_099_999_999))
      expect(@d_user).to be_a User
      expect(@d_user.id).to equal @user.id
      @d_email = @d_user.email
      create_admin
      @d_user.current_admin = @admin
      @d_user.send :setup_two_factor_auth
      @d_user.new_two_factor_auth_code = false
      @d_user.otp_required_for_login = true
      @d_user.disabled = true
      @d_user.save!
      expect(@d_user.active_for_authentication?).to be false

      @user, @good_password = create_user
      @user.otp_required_for_login = false
      @user.save!
      @good_email = @user.email
    end

    it 'should allow 2FA to be set up' do
      validate_setup
      expect(User.two_factor_auth_disabled).to be false

      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_css('body.show_otp')
      expect(current_path).to have_content('/users/show_otp')

      within '#form-validate-otp' do
        fill_in 'Two-Factor Authentication Code', with: '000000'
        click_button 'Submit Code'
      end

      expect(page).to have_css '.flash .alert', text: "×\nTwo-Factor Authentication Code was incorrect. Wait for the code on your authenticator app to change, then try again."

      within '#form-validate-otp' do
        fill_in 'Two-Factor Authentication Code', with: @user.current_otp
        click_button 'Submit Code'
      end

      expect(page).to have_css('body.masters.search')
    end

    it 'should require 2FA to be set up' do
      validate_setup
      expect(User.two_factor_auth_disabled).to be false

      visit '/users/sign_in'
      within '#new_user' do
        fill_in 'Email', with: @good_email
        fill_in 'Password', with: @good_password
        click_button 'Log in'
      end

      expect(page).to have_css('body.show_otp')
      expect(current_path).to have_content('/users/show_otp')

      visit '/masters'
      expect(page).to have_css('body.show_otp')
      expect(current_path).to have_content('/users/show_otp')
    end
  end

  after(:all) do
  end
end
