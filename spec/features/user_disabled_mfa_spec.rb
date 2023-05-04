# frozen_string_literal: true

require 'rails_helper'

describe 'user sign in process', js: true, driver: :app_firefox_driver do
  include ModelSupport

  before(:all) do
    change_setting('AllowUsersToRegister', false)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    # create a user, then disable it
    @d_user, @d_pw = create_user(rand(100_000_000..1_099_999_999))
    expect(@d_user).to be_a User
    expect(@d_user.id).to equal @user.id
    @d_email = @d_user.email
    create_admin
    @d_user.current_admin = @admin
    # @d_user.send :setup_two_factor_auth
    @d_user.new_two_factor_auth_code = false
    @d_user.otp_required_for_login = false
    @d_user.disabled = true
    @d_user.save!
    expect(@d_user.active_for_authentication?).to be false

    @user, @good_password = create_user
    @good_email = @user.email
  end

  it 'should sign in without 2FA' do
    validate_setup
    expect(User.two_factor_auth_disabled).to be true

    visit '/users/sign_in'
    within '#new_user' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: "×\nSigned in successfully."
  end

  it 'should prevent sign in if user disabled' do
    expect(User.two_factor_auth_disabled).to be true
    visit '/users/sign_in'
    within '#new_user' do
      fill_in 'Email', with: @d_email
      fill_in 'Password', with: @d_pw
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: "×\nThis account has been disabled."
  end

  it 'should prevent invalid sign in' do
    expect(User.two_factor_auth_disabled).to be true
    expect(Admin.two_factor_auth_disabled).to be true
    validate_setup

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: ''

      click_button 'Log in'
    end

    fail_message = "×\nInvalid email, password or two-factor authentication code."

    expect(page).to have_css 'input:invalid'

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password + ' '

      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: fail_message

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: ' ' + @good_password

      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: fail_message
  end

  after(:all) do
  end
end
