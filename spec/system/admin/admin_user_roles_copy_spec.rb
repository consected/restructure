# frozen_string_literal: true

require 'rails_helper'

# System tests for the copy user roles functionality in the admin panel
# These tests verify the UI workflow for copying roles between users,
# including the new reenable_disabled option that was added.
#
# NOTE: These tests require proper admin panel setup with accessible app types.
# The model tests in spec/models/admin/user_role_spec.rb provide complete coverage
# of the underlying functionality.
describe 'admin copy user roles', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    # Store admin for user creation - make sure we use an admin
    @setup_admin = Admin.active.first || Admin.first || Admin.create!(
      email: "setup_admin_#{rand(1_000_000)}@test.com",
      password: 'Pass1234!',
      password_confirmation: 'Pass1234!',
      disabled: false
    )

    # Use an existing app type or create one
    @app_type_1 = Admin::AppType.active.first || Admin::AppType.create!(
      name: 'test_app',
      label: 'Test App',
      current_admin: @setup_admin
    )
  end

  after(:all) do
    # Cleanup is handled by DatabaseCleaner
  end

  before(:each) do
    # Create admin for login (using login_as helper)
    make_an_admin

    # Login the admin using Devise test helper
    login_as(@admin, scope: :admin)

    # Create test users
    @source_user, = create_user(email: "source_template_#{rand(1_000_000_000)}@template")
    @target_user, = create_user(email: "target_user_#{rand(1_000_000_000)}@testing.com")
    @target_with_roles, = create_user(email: "target_with_roles_#{rand(1_000_000_000)}@testing.com")

    # Create roles for source user (template)
    @role_names = ['researcher', 'data_entry', 'coordinator']
    @role_names.each do |role_name|
      Admin::UserRole.create!(
        user: @source_user,
        app_type: @app_type_1,
        role_name: role_name,
        current_admin: @admin
      )
    end

    # Create some roles for target_with_roles user and disable some
    Admin::UserRole.create!(
      user: @target_with_roles,
      app_type: @app_type_1,
      role_name: 'researcher',
      current_admin: @admin
    )

    disabled_role = Admin::UserRole.create!(
      user: @target_with_roles,
      app_type: @app_type_1,
      role_name: 'data_entry',
      current_admin: @admin
    )
    disabled_role.update!(disabled: true, current_admin: @admin)

    disabled_role2 = Admin::UserRole.create!(
      user: @target_with_roles,
      app_type: @app_type_1,
      role_name: 'coordinator',
      current_admin: @admin
    )
    disabled_role2.update!(disabled: true, current_admin: @admin)
  end

  # Helper method to select from chosen dropdown when we have the field ID
  # Admin forms don't have data-attr-name, so we can't use select_from_chosen directly
  def select_from_chosen_by_id(field_id, value)
    chosen_id = "#{field_id}_chosen"

    # Click the chosen container to open dropdown
    find("##{chosen_id}").click

    # Wait for dropdown to appear and be populated
    results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
    expect(page).to have_css(results_selector, wait: 5)

    # Find all results
    results = all(results_selector)

    # Find the matching option
    matching = results.find { |r| r.text.downcase == value.downcase }
    raise "Could not find option '#{value}' in dropdown. Available: #{results.map(&:text).inspect}" unless matching

    matching.click

    # Wait for chosen to update
    sleep 0.3
  end

  it 'copies roles from source to target user' do
    # Navigate to user roles page
    visit admin_user_roles_path
    finish_page_loading

    expect(page).to have_content('Copy Roles from One User to Another')

    # Expand the copy roles form
    find('a[href="#copy-roles-block"]').click
    sleep 0.5

    # Select source user - NOTE: chosen dropdowns appear at body level, so don't use within blocks
    select_from_chosen_by_id('from_user_id', @source_user.email)

    # Select target user
    select_from_chosen_by_id('to_user_id', @target_user.email)

    within '#copy-roles-block' do
      # Select first available app type (label may differ from name)
      app_type_select = find('select[name="app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }

      raise 'No app types available in dropdown' unless available_options.any?

      select available_options.first.text, from: 'app_type_id'

      # Submit the form
      click_button 'copy'
    end

    finish_page_loading

    # Verify success message
    expect(page).to have_content("#{@target_user.email} now has 3 new roles for app #{@app_type_1.name}")

    # Verify roles were created in database
    target_roles = Admin::UserRole.active.where(user: @target_user, app_type: @app_type_1)
    expect(target_roles.count).to eq 3
    expect(target_roles.pluck(:role_name).sort).to eq @role_names.sort
  end

  it 'prevents copying to user with existing roles without force option' do
    visit admin_user_roles_path
    finish_page_loading

    # Expand the copy roles form
    find('a[href="#copy-roles-block"]').click
    sleep 0.5

    # Select source and target users
    select_from_chosen_by_id('from_user_id', @source_user.email)
    select_from_chosen_by_id('to_user_id', @target_with_roles.email)

    within '#copy-roles-block' do
      # Select first available app type
      app_type_select = find('select[name="app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      select available_options.first.text, from: 'app_type_id'

      # Don't check force_not_empty
      click_button 'copy'
    end

    finish_page_loading

    # Should show error
    expect(page).to have_content('Unexpected Error')
    expect(page).to have_content('can not copy roles to a user with roles in the following app')
  end

  it 'copies roles with force_not_empty option' do
    visit admin_user_roles_path
    finish_page_loading

    # Get initial count of active roles
    initial_active_count = Admin::UserRole.active.where(user: @target_with_roles, app_type: @app_type_1).count

    # Expand the copy roles form
    find('a[href="#copy-roles-block"]').click
    sleep 0.5

    # Select source and target users
    select_from_chosen_by_id('from_user_id', @source_user.email)
    select_from_chosen_by_id('to_user_id', @target_with_roles.email)

    within '#copy-roles-block' do
      # Select first available app type
      app_type_select = find('select[name="app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      select available_options.first.text, from: 'app_type_id'

      # Check force_not_empty
      check 'force_not_empty'

      click_button 'copy'
    end

    finish_page_loading

    # Should show success but with 0 new roles (all already exist)
    expect(page).to have_content("#{@target_with_roles.email} now has 0 new roles for app #{@app_type_1.name}")

    # Active roles count should be unchanged (disabled roles remain disabled)
    current_active_count = Admin::UserRole.active.where(user: @target_with_roles, app_type: @app_type_1).count
    expect(current_active_count).to eq initial_active_count
  end

  it 're-enables disabled roles with reenable_disabled option' do
    visit admin_user_roles_path
    finish_page_loading

    # Expand the copy roles form
    find('a[href="#copy-roles-block"]').click
    sleep 0.5

    # Select source and target users
    select_from_chosen_by_id('from_user_id', @source_user.email)
    select_from_chosen_by_id('to_user_id', @target_with_roles.email)

    within '#copy-roles-block' do
      # Select first available app type
      app_type_select = find('select[name="app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      select available_options.first.text, from: 'app_type_id'

      # Check both options
      check 'force_not_empty'
      check 'reenable_disabled'

      click_button 'copy'
    end

    finish_page_loading

    # Should show success with 2 re-enabled roles
    expect(page).to have_content("#{@target_with_roles.email} now has 2 new roles for app #{@app_type_1.name}")

    # All roles should now be active
    active_roles = Admin::UserRole.active.where(user: @target_with_roles, app_type: @app_type_1)
    expect(active_roles.count).to eq 3
    expect(active_roles.pluck(:role_name).sort).to eq @role_names.sort

    # Verify the previously disabled roles are now enabled
    all_roles = Admin::UserRole.where(user: @target_with_roles, app_type: @app_type_1)
    expect(all_roles.where(disabled: true).count).to eq 0
  end
end
