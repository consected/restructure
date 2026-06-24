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
# - 2FA set up? column displays correct status per user
#
# Related issues: #1025 (api_access_only flag), #330, #1047 (2FA column), #1096 (email/first/last filters)

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
    # Re-enable the test user in case a prior test disabled them
    User.find_by(email: @test_user_email)&.update(disabled: false)

    change_setting('AllowUsersToRegister', false)
    change_setting('TwoFactorAuthDisabledForUser', false)
    admin_sign_in_with_2fa
  end

  after(:each) do
    change_setting('AllowUsersToRegister', false)
    change_setting('TwoFactorAuthDisabledForUser', false)
  end

  def visit_manage_users_page
    visit '/admin/manage_users'
    finish_page_loading
  end

  def click_add_user_button
    all('a.add-item-button').first.click
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)
  end

  def fill_user_form(email:, first_name:, last_name:)
    find("input[name='user[email]']").set(email)
    find("input[name='user[first_name]']").set(first_name)
    find("input[name='user[last_name]']").set(last_name)
  end

  def submit_user_form
    first('input[type="submit"]').click
  end

  def click_edit_for_user(email)
    user_row = find('td', text: email).ancestor('tr')
    within(user_row) do
      find('a.edit-entity.glyphicon-pencil').click
    end
    expect(page).to have_css('#admin-edit- .admin-edit-form', wait: 10)
  end

  # Rails check_box generates a hidden input + visible checkbox.
  # Use JS to set the checked state to avoid Capybara ambiguity.
  def check_admin_checkbox(field_name)
    page.execute_script(
      "document.querySelector(\"input[type='checkbox'][name='user[#{field_name}]']\").checked = true"
    )
  end

  context 'when adding users' do
    it 'adds a new user and shows credential document' do
      visit_manage_users_page

      expect(page).to have_content('Usernames and Passwords')

      click_add_user_button

      new_email = "new_std_user_#{SecureRandom.hex(4)}@test.com"

      within('#admin-edit- .admin-edit-form') do
        fill_user_form(email: new_email, first_name: 'Standard', last_name: 'Testuser')
        submit_user_form
      end

      expect(page).to have_content('New password:', wait: 10)
      expect(page).to have_content(new_email)
      expect(page).to have_content('Standard')
      expect(page).to have_content('Testuser')
    end

    it 'shows a view user record link that navigates to the user row' do
      visit_manage_users_page
      click_add_user_button

      new_email = "new_view_link_#{SecureRandom.hex(4)}@test.com"

      within('#admin-edit- .admin-edit-form') do
        fill_user_form(email: new_email, first_name: 'Viewlink', last_name: 'Testuser')
        submit_user_form
      end

      expect(page).to have_content('New password:', wait: 10)
      expect(page).to have_link('View user record', wait: 5)

      click_link 'View user record'
      finish_page_loading

      expect(page).to have_css('td', text: new_email)
      user_row = find('tr', text: new_email)
      within(user_row) do
        expect(page).to have_content('Viewlink')
        expect(page).to have_content('Testuser')
      end
    end

    it 'adds an API-access-only user and shows API credentials' do
      visit_manage_users_page
      click_add_user_button

      api_email = "api_user_#{SecureRandom.hex(4)}@test.com"

      within('#admin-edit- .admin-edit-form') do
        fill_user_form(email: api_email, first_name: 'Api', last_name: 'OnlyUser')
        check_admin_checkbox('api_access_only')
        submit_user_form
      end

      expect(page).to have_content('New API token:', wait: 10)
      expect(page).to have_content(api_email)
    end

    it 'enforces email validation on create' do
      visit_manage_users_page
      click_add_user_button

      within('#admin-edit- .admin-edit-form') do
        fill_user_form(email: 'not-a-valid-email', first_name: 'Bad', last_name: 'Email')
        submit_user_form
      end

      # HTML5 email validation prevents submission - the form stays open with invalid field
      expect(page).to have_css('input:invalid', wait: 5)
    end
  end

  context 'when editing users' do
    it 'disables an existing user' do
      visit_manage_users_page
      click_edit_for_user(@test_user_email)

      within('#admin-edit- .admin-edit-form') do
        check_admin_checkbox('disabled')
        submit_user_form
      end

      # The show partial confirms the disabled state
      expect(page).to have_content('Disabled:true', wait: 10)

      # The default filter shows only enabled users, so the disabled user
      # should no longer appear in the table after the AJAX re-render
      expect(page).not_to have_css('td', text: @test_user_email)
    end
  end

  context 'when 2FA setting varies' do
    it 'shows 2FA set up column with correct status for each user' do
      visit_manage_users_page

      # The column header should be present
      expect(page).to have_css('th', text: '2FA set up?')

      # The test user was created with 2FA enabled, so they have an OTP secret
      user_row = find('td', text: @test_user_email).ancestor('tr')
      within(user_row) do
        # Find the 2FA column cell - it's rendered by index_list_item_boolean_field
        tds = all('td')
        # The 2FA column uses val-checked (checkmark) when otp_secret is present
        two_fa_user = User.find_by(email: @test_user_email)
        if two_fa_user.otp_secret.present?
          expect(user_row).to have_css('.val-checked')
        else
          expect(user_row).to have_css('.val-unchecked')
        end
      end
    end

    it 'shows 2FA reset option when 2FA is enforced' do
      visit_manage_users_page
      click_edit_for_user(@test_user_email)

      within('#admin-edit- .admin-edit-form') do
        expect(page).to have_content('Reset two factor auth')
      end
    end

    it 'hides 2FA reset option when 2FA is disabled for users' do
      change_setting('TwoFactorAuthDisabledForUser', true)

      visit_manage_users_page
      click_edit_for_user(@test_user_email)

      within('#admin-edit- .admin-edit-form') do
        expect(page).not_to have_content('Reset two factor auth')
      end
    end
  end

  context 'when self-registration setting varies' do
    it 'shows self-registration info when AllowUsersToRegister is enabled' do
      change_setting('AllowUsersToRegister', true)
      change_setting('InvitationCode', 'SPEC-TEST-CODE')

      visit_manage_users_page

      expect(page).to have_content('User Registration')
      expect(page).to have_content('SPEC-TEST-CODE')
    end

    it 'shows "Adding Users" info when self-registration is disabled' do
      visit_manage_users_page

      expect(page).to have_content('Adding Users')
      expect(page).not_to have_content('User Registration')
    end
  end

  context 'when filtering users - Issue #1096' do
    it 'filters by email, first name and last name' do
      user, = create_user(nil, '', email: "issue1096_#{SecureRandom.hex(4)}@testing.com")
      user.update!(
        first_name: 'Issue1096First',
        last_name: 'Issue1096Last'
      )

      visit '/admin/manage_users'
      finish_page_loading

      expect(page).to have_content('Email:')
      expect(page).to have_content('First name:')
      expect(page).to have_content('Last name:')

      visit "/admin/manage_users?filter[email]=#{CGI.escape(user.email)}"
      finish_page_loading
      expect(page).to have_css('td', text: user.email)
      expect(page).not_to have_css('td', text: @test_user_email)

      visit "/admin/manage_users?filter[first_name]=#{CGI.escape(user.first_name)}"
      finish_page_loading
      expect(page).to have_css('td', text: user.email)
      expect(page).not_to have_css('td', text: @test_user_email)

      visit "/admin/manage_users?filter[last_name]=#{CGI.escape(user.last_name)}"
      finish_page_loading
      expect(page).to have_css('td', text: user.email)
      expect(page).not_to have_css('td', text: @test_user_email)
    end
  end
end
