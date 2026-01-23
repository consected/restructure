# frozen_string_literal: true

require 'rails_helper'

# Tests the "In current app type" column rendering in admin index pages for:
# - Dynamic Models
# - External Identifiers
# - Activity Logs
#
# Issue #859 (Dynamic Models, External Identifiers)
# Issue #867 (Activity Logs)
#
# The column shows a checkbox indicating whether each definition is associated
# with the admin's current app type via User Access Controls.
describe 'admin definition in current app type column', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    # Create an app type for testing
    @app_type = create_app_type(name: "def_column_test_#{rand(100_000)}", label: 'Def Column Test')

    # Create a matching user for the admin (same email) so that admin.matching_user works
    # The matching_user method finds a user by email matching the admin's email
    @matching_user = User.find_by(email: @admin.email) || User.create!(
      email: @admin.email,
      first_name: 'Admin',
      last_name: 'Matching',
      current_admin: @admin
    )

    # Grant user access to the app type
    Admin::UserAccessControl.create!(
      app_type: @app_type,
      user: @matching_user,
      resource_type: :general,
      resource_name: :app_type,
      access: :read,
      current_admin: @admin
    )

    # Set app_type on the matching user so admin.matching_user.app_type returns it
    @matching_user.app_type = @app_type
    @matching_user.save!
  end

  after(:all) do
    @app_type&.update!(disabled: true, current_admin: @admin)
  end

  describe 'Dynamic Models admin index' do
    it 'shows "In current app type" column header' do
      admin_sign_in_with_2fa
      visit '/admin/dynamic_models'
      finish_page_loading

      # Check for the column header
      within 'table.common-template-index-table thead' do
        expect(page).to have_content('In current app type')
      end
    end

    it 'shows boolean indicators in the In current app type column' do
      admin_sign_in_with_2fa
      visit '/admin/dynamic_models'
      finish_page_loading

      # Check that at least one row has a boolean indicator for the column
      # The method in_current_app_type_result_checkbox returns glyphicon-check or val-unchecked
      expect(page).to have_css('table.common-template-index-table tbody tr', minimum: 1)

      # Find boolean indicators in the table body (checked or unchecked)
      within 'table.common-template-index-table tbody' do
        expect(page).to have_css('.val-checked, .val-unchecked', minimum: 1)
      end
    end
  end

  describe 'External Identifiers admin index' do
    it 'shows "In current app type" column header' do
      admin_sign_in_with_2fa
      visit '/admin/external_identifiers'
      finish_page_loading

      within 'table.common-template-index-table thead' do
        expect(page).to have_content('In current app type')
      end
    end

    it 'shows boolean indicators in the In current app type column' do
      admin_sign_in_with_2fa
      visit '/admin/external_identifiers'
      finish_page_loading

      expect(page).to have_css('table.common-template-index-table tbody tr', minimum: 1)

      within 'table.common-template-index-table tbody' do
        expect(page).to have_css('.val-checked, .val-unchecked', minimum: 1)
      end
    end
  end

  describe 'Activity Logs admin index' do
    it 'shows "In current app type" column header' do
      admin_sign_in_with_2fa
      visit '/admin/activity_logs'
      finish_page_loading

      within 'table.common-template-index-table thead' do
        expect(page).to have_content('In current app type')
      end
    end

    it 'shows boolean indicators in the In current app type column' do
      admin_sign_in_with_2fa
      visit '/admin/activity_logs'
      finish_page_loading

      expect(page).to have_css('table.common-template-index-table tbody tr', minimum: 1)

      within 'table.common-template-index-table tbody' do
        expect(page).to have_css('.val-checked, .val-unchecked', minimum: 1)
      end
    end
  end
end
