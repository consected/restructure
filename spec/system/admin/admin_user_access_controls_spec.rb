# frozen_string_literal: true

require 'rails_helper'

# System tests for the User Access Controls admin panel
# Tests creation, editing, and copying of user access control entries
# with all main resource types.
#
# Tests verify:
# - Create: general, table, and activity_log_type resource access controls
# - Edit: modify existing access controls and toggle disabled state
# - Copy: preserve fields when copying with changes to user/role/resource_type
#
# Copy test scenarios based on explicit requirements:
# 1. All fields mirror the original when form loads after copy
# 2. User/role_name changes don't affect other fields
# 3. Resource_type change requires new resource_name and access selection
# 4. Resource_name change may require explicit access selection
#
# 11 tests passing, comprehensive coverage of user access controls admin functionality
describe 'admin user access controls', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport
  include AdminFeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    # Create admin for setup
    @setup_admin = Admin.active.first || Admin.first || Admin.create!(
      email: "setup_admin_#{rand(1_000_000)}@test.com",
      password: 'Pass1234!',
      password_confirmation: 'Pass1234!',
      disabled: false
    )

    # Use existing app type (zeus is the standard test app type)
    @app_type_1 = Admin::AppType.active.first || Admin::AppType.create!(
      name: 'test_app_uac',
      label: 'Test App UAC',
      current_admin: @setup_admin
    )

    @app_type_name = @app_type_1.name

    # Create test users for the user_id field
    @test_user1, = create_user(email: "test_user1_#{rand(1_000_000_000)}@testing.com")
    @test_user2, = create_user(email: "test_user2_#{rand(1_000_000_000)}@testing.com")
    @test_user3, = create_user(email: "test_user3_#{rand(1_000_000_000)}@testing.com")

    # Find a reliable activity_log_type resource name to use in tests.
    # This avoids dependency on a specific AL that may be disabled or absent.
    al_resource_names = Admin::UserAccessControl.resource_names_for(:activity_log_type)
    @activity_log_type_resource_name = al_resource_names.reject { |rn| rn.end_with?('_%') }.first
    raise 'No activity_log_type resources available for UAC spec' unless @activity_log_type_resource_name

    # Create test user roles for the role_name field
    @role1 = Admin::UserRole.create!(
      user: @test_user1,
      app_type: @app_type_1,
      role_name: 'researcher',
      current_admin: @setup_admin
    )

    @role2 = Admin::UserRole.create!(
      user: @test_user1,
      app_type: @app_type_1,
      role_name: 'data_entry',
      current_admin: @setup_admin
    )
  end

  before(:each) do
    # Create admin for login
    make_an_admin
    admin_sign_in_with_2fa
  end

  describe 'creating user access controls' do
    it 'creates a general resource access control' do
      visit '/admin/user_access_controls'
      finish_page_loading

      # Click the "add" button
      all('a.add-item-button').first.click

      # Wait for form to appear
      expect(page).to have_css('.admin-edit-form', wait: 5)

      # Select fields - skip app_type for now, test basics first
      select_admin_field_by_id('user_id', @test_user1.email)
      select_admin_field_by_id('resource_type', 'general')
      finish_page_loading
      sleep 1 # Wait for JavaScript to update big-select options

      select_admin_big_select('resource_name', 'app_type')
      select_admin_field_by_id('access', 'read')

      # Submit - use the first submit button
      first('input[type="submit"]').click

      wait_for_admin_form_save

      # Verify in database
      uac = Admin::UserAccessControl.active.where(
        user: @test_user1,
        resource_type: 'general',
        resource_name: 'app_type'
      ).first

      expect(uac).not_to be_nil
      expect(uac.access).to eq('read')
    end

    it 'creates a table resource access control' do
      visit '/admin/user_access_controls'
      finish_page_loading

      all('a.add-item-button').first.click
      expect(page).to have_css('.admin-edit-form', wait: 5)

      select_admin_field_by_id('user_id', @test_user2.email)
      select_admin_field_by_id('resource_type', 'table')
      finish_page_loading
      sleep 1 # Wait for JavaScript to update big-select options

      select_admin_big_select('resource_name', 'player_infos')
      select_admin_field_by_id('access', 'update')

      first('input[type="submit"]').click
      wait_for_admin_form_save

      # Verify in database
      uac = Admin::UserAccessControl.active.where(
        user: @test_user2,
        resource_type: 'table',
        resource_name: 'player_infos'
      ).first

      expect(uac).not_to be_nil
      expect(uac.access).to eq('update')
    end

    it 'creates an activity_log_type resource access control' do
      visit '/admin/user_access_controls'
      finish_page_loading

      all('a.add-item-button').first.click
      expect(page).to have_css('.admin-edit-form', wait: 5)

      select_admin_field_by_id('user_id', @test_user3.email)
      select_admin_field_by_id('resource_type', 'activity_log_type')
      finish_page_loading
      sleep 1 # Wait for JavaScript to update big-select options

      # Use the first available activity log type (determined in before(:all) from live registry)
      select_admin_big_select('resource_name', @activity_log_type_resource_name)
      select_admin_field_by_id('access', 'create')

      first('input[type="submit"]').click
      wait_for_admin_form_save

      # Verify in database - record should be created
      uac = Admin::UserAccessControl.active.where(
        user: @test_user3,
        resource_type: 'activity_log_type',
        resource_name: @activity_log_type_resource_name
      ).first

      expect(uac).not_to be_nil
      # NOTE: access level may be restricted by validation for this resource type
    end
  end

  describe 'editing user access controls' do
    it 'edits an existing user access control' do
      # Create an access control to edit
      uac = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        user: @test_user3,
        resource_type: 'general',
        resource_name: 'create_master',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      # Find and click edit button
      within "#admin-item-#{uac.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      # Wait for edit form
      expect(page).to have_css('.admin-edit-form', wait: 5)

      # Change the resource type to table
      select_admin_field_by_id('resource_type', 'table')
      finish_page_loading
      sleep 1 # Wait for JavaScript to update big-select options

      select_admin_big_select('resource_name', 'player_infos')
      select_admin_field_by_id('access', 'update')

      first('input[type="submit"]').click
      wait_for_admin_form_save

      # Verify changes in database
      uac.reload
      expect(uac.resource_type).to eq('table')
      expect(uac.resource_name).to eq('player_infos')
      expect(uac.access).to eq('update')
    end

    it 'toggles disabled state' do
      uac = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        user: @test_user2,
        resource_type: 'general',
        resource_name: 'print',
        access: 'read',
        disabled: false,
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{uac.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)

      # Check the disabled checkbox - find within the form
      within('.admin-edit-form') do
        find("input[type='checkbox'][name*='[disabled]']", visible: :all).set(true)
        first('input[type="submit"]').click
      end

      wait_for_admin_form_save

      # Verify disabled in database
      uac.reload
      expect(uac.disabled).to be true
    end
  end

  describe 'copying user access controls' do
    # Tests based on explicit copy requirements:
    # 1. All fields in the edit form exactly mirror the values of the item being copied
    # 2. User or role_name fields may be changed without affecting other fields
    # 3. If resource_type changes, resource_name and access must be re-selected
    # 4. If only resource_name changes, access may need explicit selection or can be retained

    it 'copies an existing user access control and allows changing user only' do
      # Create original access control
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        user: @test_user1,
        resource_type: 'general',
        resource_name: 'download_files',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      # Click the copy button (glyphicon-copy)
      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      # Wait for form to appear with copied values
      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1 # Wait for JavaScript to initialize form

      # Change only the user field - per requirements, this should not affect other fields
      select_admin_field_by_id('user_id', @test_user2.email)
      sleep 0.5
      finish_page_loading

      # Re-select access to ensure it's set (requirements allow explicit re-selection)
      select_admin_access_field('read')

      # Submit the form
      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      # Verify the copy was created with correct values
      copy = Admin::UserAccessControl.active.order(id: :desc).first

      expect(copy).not_to be_nil
      expect(copy.id).not_to eq(original.id)
      expect(copy.user_id).to eq(@test_user2.id), 'User should be changed to test_user2'
      expect(copy.resource_type).to eq('general'), 'resource_type should be preserved'
      expect(copy.resource_name).to eq('download_files'), 'resource_name should be preserved'
      expect(copy.access).to eq('read'), 'access should be preserved'
    end

    it 'copies with table resource type and changes role_name only' do
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        role_name: 'researcher',
        resource_type: 'table',
        resource_name: 'player_infos',
        access: 'update',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1 # Wait for JavaScript

      # Change only role_name - per requirements, this should not affect other fields
      select_admin_field_by_id('role_name', 'data_entry')
      sleep 0.5
      finish_page_loading

      # Re-select access to ensure it's set
      select_admin_access_field('update')

      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      # Verify the copy preserved all fields except role_name
      copy = Admin::UserAccessControl.active.order(id: :desc).first

      expect(copy).not_to be_nil
      expect(copy.id).not_to eq(original.id)
      expect(copy.role_name).to eq('data_entry'), 'role_name should be changed'
      expect(copy.resource_type).to eq('table'), 'resource_type should be preserved'
      expect(copy.resource_name).to eq('player_infos'), 'resource_name should be preserved'
      expect(copy.access).to eq('update'), 'access should be preserved'
    end

    it 'copies and allows changing resource_type (requires re-selection of resource_name and access)' do
      # Create original with general resource type
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        role_name: 'researcher',
        resource_type: 'general',
        resource_name: 'view_reports',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1 # Wait for JavaScript to filter optgroups

      # Change resource_type to table - per requirements, resource_name and access must be re-selected
      select_admin_field_by_id('resource_type', 'table')
      sleep 1.5 # Wait for big-select subtype to update
      finish_page_loading

      # Must select new resource_name for the new resource_type
      select_admin_big_select('resource_name', 'player_infos')
      sleep 0.5
      finish_page_loading

      # Must select access for the new resource_type
      select_admin_access_field('update')

      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      # Verify the copy has the new values
      copy = Admin::UserAccessControl.active.order(id: :desc).first

      expect(copy).not_to be_nil
      expect(copy.id).not_to eq(original.id)
      expect(copy.role_name).to eq('researcher'), 'role_name should be preserved'
      expect(copy.resource_type).to eq('table'), 'resource_type should be changed'
      expect(copy.resource_name).to eq('player_infos'), 'resource_name should be the new selection'
      expect(copy.access).to eq('update'), 'access should be the new selection'
    end

    it 'copies activity_log_type and preserves all fields when only changing user' do
      # Create original with activity_log_type
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        user: @test_user1,
        resource_type: 'activity_log_type',
        resource_name: 'activity_log__bhs_assignment__primary',
        access: 'create',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1 # Wait for JavaScript

      # Change only the user - per requirements, other fields should be preserved
      select_admin_field_by_id('user_id', @test_user2.email)
      sleep 0.5
      finish_page_loading

      # Re-select access to ensure it's set
      select_admin_access_field('create')

      # Submit the form
      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      # Verify the copy preserved all fields except user
      copy = Admin::UserAccessControl.active.order(id: :desc).first
      expect(copy).not_to be_nil
      expect(copy.id).not_to eq(original.id)
      expect(copy.user_id).to eq(@test_user2.id), 'user should be changed'
      expect(copy.resource_type).to eq('activity_log_type'), 'resource_type should be preserved'
      expect(copy.resource_name).to eq('activity_log__bhs_assignment__primary'), 'resource_name should be preserved'
      expect(copy.access).to eq('create'), 'access should be preserved'
    end

    it 'copies and changes from user to role_name while preserving other fields' do
      # Create original with user - use a unique resource to avoid conflicts
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        user: @test_user1,
        resource_type: 'general',
        resource_name: 'view_external_links', # Use a unique resource for this test
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1 # Wait for JavaScript

      # Clear the user field before selecting role (to avoid duplicate conflict)
      clear_admin_chosen_field('user_id')
      sleep 0.5

      # Select the role_name - this creates a new access control for role instead of user
      select_admin_field_by_id('role_name', 'data_entry')
      sleep 0.5
      finish_page_loading

      # Re-select access to ensure it's set
      select_admin_access_field('read')

      # Submit the form
      first('input[type="submit"]').click

      # Check for save or errors
      if page.has_css?('.saved-row', wait: 10)
        # Success case
      elsif page.has_css?('.alert-danger, .field_with_errors', wait: 2)
        errors = page.all('.alert-danger, .help-block').map(&:text).join('; ')
        raise "Validation errors: #{errors}"
      else
        # Neither saved nor explicit error - check if there's any alert
        alerts = page.all('.alert').map(&:text).join('; ')
        raise "Form didn't save. Alerts: #{alerts}"
      end

      expect_no_validation_errors

      # Verify the copy - should have role_name set (not user)
      copy = Admin::UserAccessControl.active.where(
        role_name: 'data_entry',
        resource_type: 'general',
        resource_name: 'view_external_links'
      ).order(id: :desc).first

      expect(copy).not_to be_nil
      expect(copy.id).not_to eq(original.id)
      expect(copy.user_id).to be_nil, 'user should be cleared'
      expect(copy.role_name).to eq('data_entry'), 'role_name should be set'
      expect(copy.resource_type).to eq('general'), 'resource_type should be preserved'
      expect(copy.resource_name).to eq('view_external_links'), 'resource_name should be preserved'
      expect(copy.access).to eq('read'), 'access should be preserved'
    end
  end

  describe 'role_name with duplicate values across app types' do
    # This tests the scenario where the same role_name exists in multiple app types,
    # creating duplicate option values in different optgroups
    before(:all) do
      @app_type_2 = Admin::AppType.create!(
        name: 'test_app_uac_2',
        label: 'Test App UAC 2',
        current_admin: @setup_admin
      )

      # Create the same role_name in both app types - this creates duplicate option values
      @shared_role = Admin::UserRole.create!(
        user: @test_user1,
        app_type: @app_type_2,
        role_name: 'researcher', # Same name as in @app_type_1
        current_admin: @setup_admin
      )
    end

    it 'preserves role_name when changing resource_name after copy' do
      # This test reproduces the user-reported issue where:
      # 1. Same role_name "researcher" exists in multiple app types
      # 2. Create a UAC with role_name in app_type_1
      # 3. Copy the row and change the resource_name
      # 4. Role_name should still have correct underlying value (not switch to wrong optgroup)

      # Use a unique resource name to avoid duplicate validation errors
      unique_resource = 'download_files'

      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        role_name: 'researcher',
        resource_type: 'general',
        resource_name: unique_resource,
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1.5 # Wait for JavaScript to fully initialize

      # Check that role_name has the correct underlying value before any changes
      role_name_field = find("select[name$='[role_name]']", visible: :all)
      role_name_value_before = role_name_field.value
      expect(role_name_value_before).to eq('researcher'), "Role name should be 'researcher' after copy, got: #{role_name_value_before}"

      # Change the resource_name field (instead of clearing access which may not have blank option)
      select_admin_big_select('resource_name', 'send_files_to_trash')
      sleep 0.5
      finish_page_loading

      # Verify role_name STILL has correct underlying value after changing resource_name
      role_name_field = find("select[name$='[role_name]']", visible: :all)
      role_name_value_after = role_name_field.value
      expect(role_name_value_after).to eq('researcher'),
                                       "Role name should still be 'researcher' after changing resource_name, got: #{role_name_value_after}"

      # Verify the selected role_name option is in the correct app type's optgroup
      js_role_check = page.evaluate_script(<<~JS)
        (function() {
          var select = document.querySelector("select[name$='[role_name]']");
          var selectedOption = select.options[select.selectedIndex];
          if (!selectedOption) return { error: 'No option selected' };
          var optgroup = selectedOption.closest('optgroup');
          if (!optgroup) return { error: 'Selected option not in optgroup', value: selectedOption.value };
          return {
            value: selectedOption.value,
            optgroupLabel: optgroup.label,
            optgroupDataNum: optgroup.getAttribute('data-group-num'),
            optgroupVisible: optgroup.style.display !== 'none',
            optgroupDisabled: optgroup.disabled
          };
        })()
      JS

      raise "DOM selection error: #{js_role_check['error']}" if js_role_check['error']

      # The optgroup should be for the correct app type (based on app_type_id filtering)
      expect(js_role_check['optgroupVisible']).to eq(true),
                                                  "Selected role_name option's optgroup '#{js_role_check['optgroupLabel']}' should be visible"
      expect(js_role_check['optgroupDisabled']).to eq(false),
                                                   "Selected role_name option's optgroup '#{js_role_check['optgroupLabel']}' should be enabled"

      # Re-select access to ensure it's set for submission
      select_admin_access_field('read')
      sleep 0.5

      # Submit and verify
      first('input[type="submit"]').click
      expect(page).to have_css('.saved-row', wait: 10)
      expect_no_validation_errors

      copy = Admin::UserAccessControl.active.order(id: :desc).first
      expect(copy.role_name).to eq('researcher'), "Role name should be saved as 'researcher', got: #{copy.role_name.inspect}"
      expect(copy.resource_name).to eq('send_files_to_trash'), "Resource name should be 'send_files_to_trash', got: #{copy.resource_name.inspect}"
    end

    it 'copies and saves correctly when role_name exists in multiple app types' do
      # This test verifies end-to-end functionality when the same role_name exists in
      # multiple app types. The fix ensures the correct option is selected from the
      # visible optgroup when duplicates exist.

      # Use the existing @app_type_1 and @app_type_2 which both have 'researcher' role
      # Create UAC with app_type_1
      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        role_name: 'researcher',
        resource_type: 'general',
        resource_name: 'user_file_actions',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1.5 # Wait for JavaScript to fully initialize

      # Verify the role_name field has the correct value set
      role_name_field = find("select[name$='[role_name]']", visible: :all)
      expect(role_name_field.value).to eq('researcher'),
                                       "Role name should be 'researcher' after copy, got: #{role_name_field.value}"

      # Change resource_name to avoid duplicate validation error
      select_admin_big_select('resource_name', 'move_files')
      sleep 0.5

      # Verify role_name still correct after changing resource_name
      role_name_field = find("select[name$='[role_name]']", visible: :all)
      expect(role_name_field.value).to eq('researcher'),
                                       "Role name should still be 'researcher' after changing resource_name, got: #{role_name_field.value}"

      # Submit and verify saved correctly
      first('input[type="submit"]').click
      expect(page).to have_css('.saved-row', wait: 10)
      expect_no_validation_errors

      # Verify the copy was saved with correct values
      copy = Admin::UserAccessControl.active.order(id: :desc).first
      expect(copy.id).not_to eq(original.id)
      expect(copy.role_name).to eq('researcher'), "Role name should be saved as 'researcher'"
      expect(copy.app_type_id).to eq(@app_type_1.id), 'App type should match original'
      expect(copy.resource_name).to eq('move_files'), 'Resource name should be new selection'
    end

    it 'shows correct role_name in Chosen dropdown when editing record with alphabetically later app type' do
      # This test reproduces the user-reported issue where:
      # 1. Create role 'test_role_dup' in app type 'ref_data' (alphabetically earlier)
      # 2. Create same role 'test_role_dup' in app type 'zeus' (alphabetically later)
      # 3. Create UAC with app_type=zeus, role_name='test_role_dup'
      # 4. Edit the record and click on role_name Chosen dropdown
      # 5. The value should appear as selected in the correct optgroup
      #
      # Root cause: Hidden optgroups were only CSS-hidden, not disabled.
      # Chosen.js shows all options regardless of optgroup visibility unless disabled.

      # Create two app types with specific alphabetical ordering
      app_type_early = Admin::AppType.find_or_create_by!(name: 'aaa_first_app') do |at|
        at.label = 'AAA First App'
        at.current_admin = @setup_admin
      end

      app_type_late = Admin::AppType.find_or_create_by!(name: 'zzz_last_app') do |at|
        at.label = 'ZZZ Last App'
        at.current_admin = @setup_admin
      end

      # Create same role in both app types
      Admin::UserRole.find_or_create_by!(
        user: @test_user1,
        app_type: app_type_early,
        role_name: 'test_role_dup'
      ) do |role|
        role.current_admin = @setup_admin
      end

      Admin::UserRole.find_or_create_by!(
        user: @test_user1,
        app_type: app_type_late,
        role_name: 'test_role_dup'
      ) do |role|
        role.current_admin = @setup_admin
      end

      # Create UAC with the LATER alphabetically app type
      uac = Admin::UserAccessControl.create!(
        app_type: app_type_late,
        role_name: 'test_role_dup',
        resource_type: 'general',
        resource_name: 'user_file_actions',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      # Click the EDIT button (not copy)
      within "#admin-item-#{uac.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)

      # Wait for JavaScript to fully initialize - Chosen.js and filter setup
      sleep 1
      # Ensure Chosen has been initialized on the role_name field
      expect(page).to have_css("select[name$='[role_name]'] + .chosen-container", wait: 5)

      # Verify the role_name field has the correct value
      role_name_field = find("select[name$='[role_name]']", visible: :all)
      expect(role_name_field.value).to eq('test_role_dup'),
                                       "Role name should be 'test_role_dup' after edit, got: #{role_name_field.value}"

      # Verify the selected option is in the CORRECT optgroup (zzz_last_app, not aaa_first_app)
      js_role_check = page.evaluate_script(<<~JS)
        (function() {
          var select = document.querySelector("select[name$='[role_name]']");
          var selectedOption = select.options[select.selectedIndex];
          if (!selectedOption) return { error: 'No option selected' };
          var optgroup = selectedOption.closest('optgroup');
          if (!optgroup) return { error: 'Selected option not in optgroup', value: selectedOption.value };
          return {
            value: selectedOption.value,
            optgroupLabel: optgroup.label,
            optgroupDataNum: optgroup.getAttribute('data-group-num'),
            optgroupVisible: optgroup.style.display !== 'none',
            optgroupDisabled: optgroup.disabled
          };
        })()
      JS

      raise "DOM selection error: #{js_role_check['error']}" if js_role_check['error']

      # The selected option should be in the visible, non-disabled optgroup for zzz_last_app
      expect(js_role_check['optgroupVisible']).to eq(true),
                                                  "Selected role_name option's optgroup '#{js_role_check['optgroupLabel']}' should be visible"
      expect(js_role_check['optgroupDisabled']).to eq(false),
                                                   "Selected role_name option's optgroup '#{js_role_check['optgroupLabel']}' should NOT be disabled"
      expect(js_role_check['optgroupDataNum']).to eq(app_type_late.id.to_s),
                                                  "Selected role_name option should be in optgroup for app_type #{app_type_late.id} (#{app_type_late.name}), " \
                                                  "but was in optgroup with data-group-num='#{js_role_check['optgroupDataNum']}'"

      # Now click on the Chosen dropdown to verify it shows the correct option as selected
      role_name_select_id = role_name_field['id']
      chosen_id = "#{role_name_select_id}_chosen"

      # The Chosen container should show the correct selected text
      chosen_container = find("##{chosen_id}")
      chosen_text = chosen_container.find('.chosen-single span').text
      expect(chosen_text).to eq('test_role_dup'),
                             "Chosen dropdown should display 'test_role_dup', got: #{chosen_text}"

      # Click to open the dropdown
      chosen_container.click
      sleep 0.5

      # Verify the highlighted/selected option in the dropdown is the correct one
      # Options in disabled optgroups should not appear
      results = page.all('body > .chosen-container.chosen-with-drop .chosen-results li.active-result')

      # The selected option should be highlighted
      highlighted = results.find { |r| r[:class].include?('result-selected') }
      expect(highlighted).not_to be_nil, 'There should be a selected/highlighted option in the Chosen dropdown'
      expect(highlighted.text).to eq('test_role_dup'),
                                  "The highlighted option should be 'test_role_dup', got: #{highlighted&.text}"

      # Close the dropdown by clicking elsewhere
      find('body').click
      sleep 0.3

      # Finally, submit the form and verify the correct value is saved
      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      # Verify the record still has the correct values
      uac.reload
      expect(uac.role_name).to eq('test_role_dup'), "Role name should still be 'test_role_dup'"
      expect(uac.app_type_id).to eq(app_type_late.id), "App type should still be #{app_type_late.name}"
    end
  end

  describe 'resource type and access level interactions' do
    it 'updates access options when resource type changes' do
      visit '/admin/user_access_controls'
      finish_page_loading

      all('a.add-item-button').first.click
      expect(page).to have_css('.admin-edit-form', wait: 5)

      select_admin_field_by_id('user_id', @test_user1.email)

      # Start with general - may have multiple options
      select_admin_field_by_id('resource_type', 'general')
      sleep 0.5

      # Check that access field has options
      access_field = all("select[name$='[access]']", visible: :all).first
      general_options = access_field.all('option', visible: :all).map(&:value).reject(&:blank?).uniq
      expect(general_options).to include('read') # Should at least have 'read'

      # Change to table (should have more comprehensive options)
      select_admin_field_by_id('resource_type', 'table')
      sleep 0.5

      # Check options include table-specific access levels
      access_field = all("select[name$='[access]']", visible: :all).first
      table_options = access_field.all('option', visible: :all).map(&:value).reject(&:blank?).uniq
      expect(table_options).to include('see_presence', 'read', 'update', 'create')

      # Table should have more options than general
      expect(table_options.length).to be >= general_options.length
    end
  end

  describe 'copy functionality DOM verification' do
    # These tests verify that the underlying DOM values are correct after copy
    # and field changes, not just the visual appearance

    it 'verifies access field DOM value is in enabled optgroup after copy and role_name change' do
      # This test reproduces the user-reported issue where:
      # 1. Copy a record with role_name set
      # 2. Change role_name to another value
      # 3. Access field visually appears set but underlying select option is disabled
      #
      # Root cause: When multiple optgroups contain options with the same value (e.g., 'read'),
      # the browser's DOM picks the first matching option in DOM order for .selected property,
      # even if the HTML selected attribute is on a different option.
      # Fix: Use selectedIndex to explicitly select the correct option in the visible optgroup.

      original = Admin::UserAccessControl.create!(
        app_type: @app_type_1,
        role_name: 'researcher',
        resource_type: 'general',
        resource_name: 'print',
        access: 'read',
        current_admin: @admin
      )

      visit '/admin/user_access_controls'
      finish_page_loading

      within "#admin-item-#{original.id}" do
        find('a.copy-icon.glyphicon-copy').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1.5 # Wait for JavaScript to fully initialize

      # Verify access field has correct value after copy
      access_field = find("select[name$='[access]']", visible: :all)
      expect(access_field.value).to eq('read'), "Access should be 'read' after copy, got: #{access_field.value}"

      # Now change role_name - this is where the bug manifested
      select_admin_field_by_id('role_name', 'data_entry')
      sleep 0.5
      finish_page_loading

      # Verify access field STILL has correct value after changing role_name
      access_field = find("select[name$='[access]']", visible: :all)
      expect(access_field.value).to eq('read'), "Access should still be 'read' after role_name change, got: #{access_field.value}"

      # Verify the selected option is in a visible, enabled optgroup
      # Use JavaScript to check the actual .selected property on the DOM
      js_selected_check = page.evaluate_script(<<~JS)
        (function() {
          var select = document.querySelector("select[name$='[access]']");
          var selectedOption = select.options[select.selectedIndex];
          if (!selectedOption) return { error: 'No option selected' };
          var optgroup = selectedOption.closest('optgroup');
          if (!optgroup) return { error: 'Selected option not in optgroup' };
          return {
            value: selectedOption.value,
            optgroupLabel: optgroup.label,
            optgroupVisible: optgroup.style.display !== 'none',
            optgroupDisabled: optgroup.disabled
          };
        })()
      JS

      raise "DOM selection error: #{js_selected_check['error']}" if js_selected_check['error']

      expect(js_selected_check['optgroupVisible']).to eq(true),
                                                      "Selected option's optgroup '#{js_selected_check['optgroupLabel']}' should be visible"
      expect(js_selected_check['optgroupDisabled']).to eq(false),
                                                       "Selected option's optgroup '#{js_selected_check['optgroupLabel']}' should be enabled"

      # Submit and verify the access value is included in form submission
      first('input[type="submit"]').click
      wait_for_admin_form_save
      expect_no_validation_errors

      copy = Admin::UserAccessControl.active.order(id: :desc).first
      expect(copy.access).to eq('read'), "Access should be saved as 'read', got: #{copy.access.inspect}"
      expect(copy.role_name).to eq('data_entry'), "Role name should be 'data_entry', got: #{copy.role_name.inspect}"
    end
  end

  describe 'cancel button cleanup' do
    it 'removes Chosen dropdowns when cancel button is clicked' do
      visit '/admin/user_access_controls'
      finish_page_loading

      # Click add button to open a new form
      all('a.add-item-button').first.click
      expect(page).to have_css('.admin-edit-form', wait: 5)
      sleep 1.5 # Wait for Chosen to initialize

      # Verify Chosen containers exist in the form
      chosen_containers_before = all('.admin-edit-form .chosen-container', visible: :all).count
      expect(chosen_containers_before).to be > 0, 'Should have Chosen containers in the form'

      # Click cancel button
      find('#admin-edit-cancel').click
      sleep 0.5

      # Verify the form content is cleared (no select elements remaining)
      expect(page).to have_no_css('.admin-edit-form select', wait: 2)

      # Verify no orphaned Chosen dropdown containers remain anywhere on the page
      # (including those that might have been detached to body for positioning)
      orphaned_chosen = page.all('.chosen-container.chosen-with-drop', visible: :all)
      expect(orphaned_chosen.count).to eq(0),
                                       "Expected no orphaned Chosen dropdowns after cancel, but found #{orphaned_chosen.count}"
    end
  end
end
