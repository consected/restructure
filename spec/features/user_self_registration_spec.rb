# frozen_string_literal: true

require 'rails_helper'

describe 'user sign in process for users that can self register', js: true, driver: :app_firefox_driver do
  include ModelSupport

  before(:all) do
    change_setting('AllowUsersToRegister', true)
    Rails.application.reload_routes!
    Rails.application.routes_reloader.reload!

    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForUser', false)
    change_setting('TwoFactorAuthDisabledForAdmin', false)

    create_admin

    # create a template user with some roles
    @template_user = RegistrationHandler.registration_template_user
    unless @template_user
      tue = Settings::DefaultUserTemplateEmail
      @template_user, = create_user(nil, '', email: tue, with_password: true, no_password_change: true)
    end

    unless @template_user.app_type_id
      grant_user_app_access @template_user
      @template_user.app_type_id = Admin::AppType.all_ids_available_to(@template_user).first
      at1 = @template_user.app_type_id
      expect(at1).not_to be nil
      @template_user.current_admin = @admin
      @template_user.save!
    end

    at1 = @template_user.app_type_id
    expect(at1).not_to be nil

    @template_user.user_roles.each { |r| r.update(disabled: true, current_admin: @admin) }
    @template_user.user_roles.create!(current_admin: @admin, role_name: 'template role 1', app_type_id: at1)
    @template_user.user_roles.create!(current_admin: @admin, role_name: 'template role 2', app_type_id: at1)

    # create a user, then disable it
    @d_user, @d_pw = create_user(rand(100_000_000..1_099_999_999))
    expect(@d_user).to be_a User
    expect(@d_user.id).to equal @user.id
    @d_email = @d_user.email

    @d_user.current_admin = @admin
    @d_user.send :setup_two_factor_auth
    @d_user.new_two_factor_auth_code = false
    @d_user.otp_required_for_login = true
    @d_user.disabled = true
    @d_user.save!
    expect(@d_user.active_for_authentication?).to be false

    @user, @good_password = create_user(rand(100_000_000..1_099_999_999))
    @good_email = @user.email

    @user.current_admin = @admin
    @user.send :setup_two_factor_auth
    @user.new_two_factor_auth_code = false
    @user.otp_required_for_login = true
    @user.save!
  end

  it 'should sign in' do
    validate_setup

    # login_as @user, scope: :user
    otp = @user.current_otp
    expect(otp).not_to be nil
    expect(@good_email).to eq @user.email
    expect(@user.disabled).to be_falsey

    visit '/users/sign_in'
    has_css? '.ready-for-2fa'
    within '#new_user' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_user', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_user' do
      fill_in 'Two-Factor Authentication Code', with: otp
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: "×\nSigned in successfully."
  end

  it 'should prevent sign in if user disabled' do
    expect(@d_user.disabled).to be true

    visit '/users/sign_in'
    has_css? '.ready-for-2fa'
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
    validate_setup

    # login_as @user, scope: :user

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    has_css? '.ready-for-2fa'
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: ''
      click_button 'Log in'
    end

    expect(page).not_to have_selector('.login-2fa-block', visible: true)

    fail_message = "×\nInvalid email, password or two-factor authentication code."

    expect(page).to have_css 'input:invalid'

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    has_css? '.ready-for-2fa'
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password + ' '
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @user.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: fail_message

    visit "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    has_css? '.ready-for-2fa'
    within '#new_admin' do
      fill_in 'Email', with: @good_email
      fill_in 'Password', with: ' ' + @good_password
      click_button 'Log in'
    end

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @user.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css '.flash .alert', text: fail_message
  end

  after(:all) do
    change_setting('AllowUsersToRegister', false)
  end
end
