# frozen_string_literal: true

# Purpose: Verify that an admin can access the "Usernames and Passwords" page
# (admin/manage_users) and reset the MFA setting for a user whose OTP secret
# is undecryptable, and that the list view does not crash.
# Related issue: #1226

require 'rails_helper'

describe 'Admin edit user with corrupt OTP secret - issue #1226', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport
  include AdminFeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForUser', false)

    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
    @admin_email = @good_email
    @admin_password = @good_password

    create_user
    @test_user_email = @user.email

    @user.reload
    @user.send(:setup_two_factor_auth) if @user.otp_secret.blank?
    @user.otp_required_for_login = true
    @user.save!

    # Restore admin credentials for admin_sign_in_with_2fa
    @good_email = @admin_email
    @good_password = @admin_password
  end

  before(:each) do
    change_setting('AllowUsersToRegister', false)
    change_setting('TwoFactorAuthDisabledForUser', false)
    User.connection.execute("UPDATE users SET otp_secret = 'not-a-valid-cipher' WHERE id = #{@user.id}")
    admin_sign_in_with_2fa
  end

  after(:each) do
    change_setting('TwoFactorAuthDisabledForUser', false)
  end

  def visit_manage_users_page
    visit '/admin/manage_users'
    finish_page_loading
  end

  def click_edit_for_user(email)
    user_row = find('td', text: email).ancestor('tr')
    within(user_row) do
      find('a.edit-entity.glyphicon-pencil').click
    end
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)
  end

  def submit_user_form
    first('input[type="submit"]').click
  end

  it 'shows the corrupt-OTP user in the list without crashing' do
    visit_manage_users_page

    # The index must render without 500 error and include the user row
    expect(page).to have_css('td', text: @test_user_email)
  end

  it 'allows admin to reset 2FA for a user with a corrupt OTP secret' do
    visit_manage_users_page
    click_edit_for_user(@test_user_email)

    within('#admin-edit- .admin-edit-form') do
      check 'Reset two factor auth'
      submit_user_form
    end

    # After save the show partial renders the user's email
    expect(page).to have_content("Email: #{@test_user_email}", wait: 10)

    # Verify the user record now has a valid (decryptable) OTP secret
    @user.reload
    expect(@user.otp_secret).to be_present
    expect(@user.otp_secret_decryption_failed?).to be false
  end
end
