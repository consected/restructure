# frozen_string_literal: true

# Admin Manage Users Page Spec - Issue #1027
#
# Tests the functionality of the admin "Usernames and Passwords" page
# (Admin::ManageUsersController / /admin/manage_users).
#
# Covers:
# - Adding a new user with standard fields
# - Adding a new API-access-only user and verifying credential display
# - Editing an existing user to disable them
# - Enforcing user validations (email format via HTML5)
# - Server option: 2FA enforcement affects form options
# - Server option: self-registration info shown vs hidden
#
# Related issues: #1025 (api_access_only flag), #330

require 'rails_helper'

describe 'admin manage users page - Issue #1027', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport
  include AdminFeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
    @admin_email = @good_email
    @admin_password = @good_password

    create_user
    @test_user_email = @user.email

    # Restore admin credentials for admin_sign_in_with_2fa
    @good_email = @admin_email
    @good_password = @admin_password
  end

  before(:each) do
    change_setting('AllowUsersToRegister', false)
    change_setting('TwoFactorAuthDisabledForUser', false)
    admin_sign_in_with_2fa
  end

  after(:each) do
    change_setting('AllowUsersToRegister', false)
    change_setting('TwoFactorAuthDisabledForUser', false)
  end

  it 'adds a new user and shows credential document' do
    visit '/admin/manage_users'
    finish_page_loading

    expect(page).to have_content('Usernames and Passwords')

    all('a.add-item-button').first.click
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    new_email = "new_std_user_#{SecureRandom.hex(4)}@test.com"

    within('#admin-edit- .admin-edit-form') do
      find("input[name='user[email]']").set(new_email)
      find("input[name='user[first_name]']").set('Standard')
      find("input[name='user[last_name]']").set('Testuser')
      first('input[type="submit"]').click
    end

    # After AJAX save, the show partial renders with credential info
    expect(page).to have_content('New password:', wait: 10)
    expect(page).to have_content(new_email)

    # Verify user appears in the list
    expect(page).to have_content('Standard')
    expect(page).to have_content('Testuser')
  end

  it 'adds an API-access-only user and shows API credentials' do
    visit '/admin/manage_users'
    finish_page_loading

    all('a.add-item-button').first.click
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    api_email = "api_user_#{SecureRandom.hex(4)}@test.com"

    within('#admin-edit- .admin-edit-form') do
      find("input[name='user[email]']").set(api_email)
      find("input[name='user[first_name]']").set('Api')
      find("input[name='user[last_name]']").set('OnlyUser')
      # Rails check_box generates hidden input + visible checkbox; use JS to check
      page.execute_script("document.querySelector(\"input[type='checkbox'][name='user[api_access_only]']\").checked = true")
      first('input[type="submit"]').click
    end

    # API-only user gets a specific credential document
    expect(page).to have_content('New API token:', wait: 10)
    expect(page).to have_content(api_email)
  end

  it 'disables an existing user' do
    visit '/admin/manage_users'
    finish_page_loading

    # Find the test user's row and click edit
    user_row = find('td', text: @test_user_email).ancestor('tr')
    within(user_row) do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    within('#admin-edit- .admin-edit-form') do
      # Rails check_box generates hidden input + visible checkbox; use JS to check
      page.execute_script("document.querySelector(\"input[type='checkbox'][name='user[disabled]']\").checked = true")
      first('input[type="submit"]').click
    end

    # Wait for AJAX save to complete - the show partial confirms the disabled state
    expect(page).to have_content('Disabled:true', wait: 10)

    # The default filter shows only enabled users, so the disabled user
    # should no longer appear in the table after the AJAX re-render
    expect(page).not_to have_css('td', text: @test_user_email)
  end

  it 'enforces email validation on create' do
    visit '/admin/manage_users'
    finish_page_loading

    all('a.add-item-button').first.click
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    within('#admin-edit- .admin-edit-form') do
      find("input[name='user[email]']").set('not-a-valid-email')
      find("input[name='user[first_name]']").set('Bad')
      find("input[name='user[last_name]']").set('Email')

      # The email field has type="email" with required: true, so HTML5 validation
      # will fire and prevent submission.
      first('input[type="submit"]').click
    end

    # HTML5 email validation should prevent submission - the form stays open with invalid field
    expect(page).to have_css('input:invalid', wait: 5)
  end

  it 'shows 2FA reset option when 2FA is enforced' do
    visit '/admin/manage_users'
    finish_page_loading

    # Edit an existing user - they should see 2FA reset option
    user_row = find('td', text: @test_user_email).ancestor('tr')
    within(user_row) do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    within('#admin-edit- .admin-edit-form') do
      expect(page).to have_content('Reset two factor auth')
    end
  end

  it 'hides 2FA reset option when 2FA is disabled for users' do
    change_setting('TwoFactorAuthDisabledForUser', true)

    visit '/admin/manage_users'
    finish_page_loading

    user_row = find('td', text: @test_user_email).ancestor('tr')
    within(user_row) do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)

    within('#admin-edit- .admin-edit-form') do
      expect(page).not_to have_content('Reset two factor auth')
    end
  end

  it 'shows self-registration info when AllowUsersToRegister is enabled' do
    change_setting('AllowUsersToRegister', true)
    change_setting('InvitationCode', 'SPEC-TEST-CODE')

    visit '/admin/manage_users'
    finish_page_loading

    expect(page).to have_content('User Registration')
    expect(page).to have_content('SPEC-TEST-CODE')
  end

  it 'shows "Adding Users" info when self-registration is disabled' do
    change_setting('AllowUsersToRegister', false)

    visit '/admin/manage_users'
    finish_page_loading

    expect(page).to have_content('Adding Users')
    expect(page).not_to have_content('User Registration')
  end
end
