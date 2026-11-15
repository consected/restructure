# frozen_string_literal: true

require 'rails_helper'

# Purpose: System spec for the User Access Overview admin reports (GitHub Issue #706).
#
# These reports provide administrators with comprehensive views of user access controls
# from multiple perspectives, accessible from the admin index page:
#
#   P1 (by_role): Tree view of UACs grouped by role name or direct assignment
#   P2 (by_resource): Tree view of UACs grouped by resource type/name
#   P3 (resolved): Tree view showing effective UAC per resource after priority resolution
#   P4 (roles_only): Tree view of roles assigned to the user, with user email as top level
#   P5 (users_with_role): Tree view of users grouped by role name
#
# The tests verify end-to-end functionality through the admin UI:
#   - Admin index page shows "User Access Overview" link under Users & Access
#   - Each perspective report loads with correct search criteria fields
#   - Reports return results when submitted with specific criteria
#   - Reports return results when all criteria are left empty (optional criteria)
#   - filter_selector on resource_type updates resource_name dropdown
#   - Inline cell links render as clickable links in report results
#   - Tree view reports display expandable tree structure
#   - Report column headers use custom labels (e.g. "Assigned via (role name)")
#
# Authentication:
#   - Admin index page tests sign in as admin via admin_sign_in_with_2fa
#   - Report tests sign in as a regular user (since ReportsController inherits from
#     UserBaseController which requires authenticate_user!). The admin reports allow
#     access to admin users via current_admin OR to users via UAC gating. For system
#     specs we sign in as a user to access the report pages normally.
describe 'admin User Access Overview reports', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include AdminActionsSetup
  include FeatureSupport
  include ReportSupport

  before(:all) do
    SetupHelper.feature_setup

    @admin, = create_admin
    seed_database
    create_data_set_outside_tx
  end

  before(:example) do
    change_setting('TwoFactorAuthDisabledForUser', true)
  end

  def setup_report_user_with_roles
    @user, @good_password = create_user
    @good_email = @user.email

    # Grant permission to view and access reports
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @admin,
      user: @user
    )
    Admin::UserAccessControl.create!(
      user: @user,
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: :_all_reports_,
      current_admin: @admin
    )

    # Grant the user roles and UACs to produce test data in the reports
    create_user_role 'editor', user: @user, app_type: @user.app_type
    create_user_role 'viewer', user: @user, app_type: @user.app_type

    # Direct (user-specific) UAC
    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      user: @user,
      access: :create,
      resource_type: :table,
      resource_name: :player_infos,
      current_admin: @admin
    )

    # Role-based UAC
    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :update,
      resource_type: :table,
      resource_name: :player_infos,
      role_name: 'editor',
      current_admin: @admin
    )

    # Another role-based UAC
    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :table,
      resource_name: :addresses,
      role_name: 'viewer',
      current_admin: @admin
    )
  end

  def navigate_to_report(short_name)
    report = Report.active.find_by(item_type: 'admin-user-access-overview', short_name: short_name)
    expect(report).to be_present, "Report '#{short_name}' not found"
    visit report_path(report)
    finish_page_loading
    report
  end

  def submit_report
    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.search-status-done', wait: 15)
    finish_page_loading
  end

  describe 'admin index page' do
    before(:example) do
      make_an_admin
      admin_sign_in_with_2fa
    end

    it 'shows User Access Overview link under Users & Access' do
      visit '/'
      finish_page_loading

      expect(page).to have_link('User Access Overview')
    end
  end

  describe 'report pages' do
    before(:example) do
      setup_report_user_with_roles
      login
    end

    describe 'By Role report (P1)' do
      it 'has correct search criteria fields' do
        navigate_to_report('user_access_overview_by_role')

        expect(page).to have_css('.report-criteria')

        # Verify all search criteria fields are present
        expect(page).to have_css('[name="search_attrs[app_type_id]"]', visible: :all)
        expect(page).to have_css('[name="search_attrs[user]"]', visible: :all)
        expect(page).to have_css('[name="search_attrs[resource_type]"]', visible: :all)
        expect(page).to have_css('[name="search_attrs[resource_name]"]', visible: :all)
        expect(page).to have_css('[name="search_attrs[role_name]"]', visible: :all)
      end

      it 'returns results with specific user criteria' do
        navigate_to_report('user_access_overview_by_role')

        # Select the test user from the user dropdown
        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        expect(page).to have_css('.report-results-block')
        # Tree view should have a table with tree-table class
        expect(page).to have_css('table.tree-table')

        # Should have data rows
        expect(page).to have_css('table.tree-table tbody tr')
      end

      it 'returns results for current user when no user is explicitly selected' do
        navigate_to_report('user_access_overview_by_role')

        # The user field defaults to current_user, so submitting without
        # explicitly selecting a user returns the current user's UACs
        submit_report

        expect(page).to have_css('.report-results-block')
        expect(page).to have_css('table.tree-table tbody tr')
        expect(page).to have_content(@user.email)
      end

      it 'renders inline links in result cells' do
        navigate_to_report('user_access_overview_by_role')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        # Resource name cells should contain clickable admin links
        within '.report-results-block' do
          links = all('a[href*="/admin/"]')
          expect(links.length).to be > 0,
                                  'Expected inline admin links in report results'
        end
      end

      it 'displays custom column headers' do
        navigate_to_report('user_access_overview_by_role')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        within '.report-results-block' do
          # Check for custom column headers
          expect(page).to have_content('Assigned via (role name)')
          expect(page).to have_content('Resource Type')
          expect(page).to have_content('Resource Name')
          expect(page).to have_content('Access')
        end
      end
    end

    describe 'By Resource report (P2)' do
      it 'returns results as a tree view' do
        navigate_to_report('user_access_overview_by_resource')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        expect(page).to have_css('table.tree-table')
        expect(page).to have_css('table.tree-table tbody tr')
      end
    end

    describe 'Resolved report (P3)' do
      it 'returns results as a tree view' do
        navigate_to_report('user_access_overview_resolved')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        expect(page).to have_css('.report-results-block')
        expect(page).to have_css('table.tree-table')
        expect(page).to have_css('table.tree-table tbody tr')
      end

      it 'displays Resolved via (role name) header' do
        navigate_to_report('user_access_overview_resolved')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        within '.report-results-block' do
          expect(page).to have_content('Resolved via (role name)')
        end
      end
    end

    describe 'Roles Only report (P4)' do
      it 'returns results as a tree view grouped by user email' do
        navigate_to_report('user_access_overview_roles_only')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        expect(page).to have_css('table.tree-table')
        expect(page).to have_css('table.tree-table tbody tr')

        # The tree should contain the test user's email
        within '.report-results-block' do
          expect(page).to have_content(@user.email)
        end
      end

      it 'returns results with default app_type and no user selected (user is optional)' do
        navigate_to_report('user_access_overview_roles_only')

        # P4 has app_type_id defaulted to current user's app type; user is optional
        submit_report

        expect(page).to have_css('table.tree-table tbody tr')
      end
    end

    describe 'Users With Role report (P5)' do
      it 'returns results as a tree view grouped by role name' do
        navigate_to_report('user_access_overview_users_with_role')

        submit_report

        expect(page).to have_css('table.tree-table')
        expect(page).to have_css('table.tree-table tbody tr')
      end

      it 'filters by user when provided' do
        navigate_to_report('user_access_overview_users_with_role')

        select_from_dropdown_field('user', @user.email, is_report: true)

        submit_report

        expect(page).to have_css('table.tree-table')
        within '.report-results-block' do
          expect(page).to have_content(@user.email)
        end
      end
    end

    describe 'filter_selector interaction' do
      it 'updates resource_name options when resource_type is selected' do
        navigate_to_report('user_access_overview_by_role')

        # Verify the filter_selector attribute is set on the resource_type field
        resource_type_select = find('[name="search_attrs[resource_type]"]', visible: :all)
        expect(resource_type_select['data-filter-selector']).to eq('resource_name')

        # Select a resource_type value
        select_from_dropdown_field('resource_type', 'table', is_report: true)
        sleep 0.5

        # After selecting resource_type, resource_name should have its
        # data-big-select-subtype attribute updated
        resource_name_select = find('[name="search_attrs[resource_name]"]', visible: :all)
        updated_subtype = resource_name_select['data-big-select-subtype']
        expect(updated_subtype).to eq('table'),
                                   "Expected resource_name subtype to be 'table', got '#{updated_subtype}'"
      end
    end
  end
end
