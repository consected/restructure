# frozen_string_literal: true

require 'rails_helper'

# Purpose: System spec for drill-down links between admin pages and the
# User Access Overview reports, and for cross-report navigation between
# the report perspectives (GitHub Issue #1125).
#
# Acceptance criteria covered:
#   1. The Usernames and Passwords admin page (manage_users) provides links
#      into the relevant User Access Overview reports for a selected user.
#   2. The User Roles admin page provides links into the relevant User Access
#      Overview reports using the selected user, role, and app type where
#      available.
#   3. The User Access Controls admin page provides links into the relevant
#      User Access Overview reports using the selected user or role, resource
#      type, resource name, and app type where available.
#   4. Where it makes sense, a User Access Overview report provides links to
#      related report perspectives with filters preserved.
#   5. Links are only shown when the target report and filter combination are
#      meaningful (e.g. role-based links require a role_name).
#
# These tests sign in as an admin and inspect the rendered HTML of each
# admin index page (no JS interactions required - the links are emitted
# server-side from the admin views/controllers).
describe 'User Access Overview drill-down links', type: :system do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    @setup_admin = Admin.active.first || Admin.create!(
      email: "setup_admin_#{rand(1_000_000)}@test.com",
      password: 'Pass1234!',
      password_confirmation: 'Pass1234!',
      disabled: false
    )

    @app_type = Admin::AppType.active.first || Admin::AppType.create!(
      name: 'test_app_drill_down',
      label: 'Test App Drill Down',
      current_admin: @setup_admin
    )

    @drill_user, = create_user(email: "drill_user_#{rand(1_000_000_000)}@testing.com")

    @role = Admin::UserRole.create!(
      user: @drill_user,
      app_type: @app_type,
      role_name: "drill_role_#{rand(1_000_000)}",
      current_admin: @setup_admin
    )

    @uac_user = Admin::UserAccessControl.create!(
      user: @drill_user,
      app_type: @app_type,
      access: :read,
      resource_type: :table,
      resource_name: :player_infos,
      current_admin: @setup_admin
    )

    @uac_role = Admin::UserAccessControl.create!(
      app_type: @app_type,
      role_name: @role.role_name,
      access: :update,
      resource_type: :table,
      resource_name: :addresses,
      current_admin: @setup_admin
    )

    # A regular user with permission to view all reports - required for
    # the cross-perspective tests that load a User Access Overview report.
    @report_user, @report_user_password = create_user(
      email: "drill_report_user_#{rand(1_000_000_000)}@testing.com"
    )
    Admin::UserAccessControl.create!(
      app_type: @report_user.app_type,
      user: @report_user,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @setup_admin
    )
    Admin::UserAccessControl.create!(
      app_type: @report_user.app_type,
      user: @report_user,
      access: :read,
      resource_type: :report,
      resource_name: :_all_reports_,
      current_admin: @setup_admin
    )
  end

  before(:each) do
    make_an_admin
    login_as(@admin, scope: :admin)
  end

  # The alt_resource_name prefix for the User Access Overview reports.
  def report_url(short_name, params = {})
    # Build the URL with params sorted alphabetically to match Rails url_for output.
    sorted = params.sort_by { |k, _| k.to_s }
    qs = sorted.map { |k, v| "search_attrs%5B#{k}%5D=#{CGI.escape(v.to_s)}" }.join('&')
    base = "/reports/admin_user_access_overview__#{short_name}"
    qs.empty? ? base : "#{base}?#{qs}"
  end

  # Capybara's default visibility filter is too strict for the admin index
  # pages where some rows/cells are hidden until expanded. These helpers
  # check link presence across all DOM links regardless of CSS visibility.
  def expect_link_with_href_including(text, expected_href)
    matching = page.all(:link, text, visible: :all).map { |l| l[:href] }
    expect(matching).to(
      include(a_string_including(expected_href)),
      "expected a link '#{text}' with href including '#{expected_href}'. Found: #{matching.inspect}"
    )
  end

  def expect_no_link_with_href_including(text, expected_href)
    matching = page.all(:link, text, visible: :all).map { |l| l[:href] }
    expect(matching).not_to include(a_string_including(expected_href))
  end

  describe 'Usernames and Passwords admin page (manage_users)' do
    it 'shows a User Access Overview link for each user' do
      visit '/admin/manage_users'

      expected = report_url('user_access_overview_by_role', user: @drill_user.id)
      expect_link_with_href_including('access overview', expected)
    end
  end

  describe 'User Roles admin page' do
    it 'shows drill-down links to User Access Overview using user, role, and app type' do
      visit "/admin/user_roles?filter%5Buser_id%5D=#{@drill_user.id}"

      user_role_link = report_url('user_access_overview_by_role',
                                  user: @drill_user.id,
                                  app_type_id: @app_type.id,
                                  role_name: @role.role_name)
      role_users_link = report_url('user_access_overview_users_with_role',
                                   app_type_id: @app_type.id,
                                   role_name: @role.role_name)

      expect_link_with_href_including('access overview', user_role_link)
      expect_link_with_href_including('users with role', role_users_link)
    end
  end

  describe 'User Access Controls admin page' do
    it 'shows a user-scoped overview link for direct (user-specific) UACs' do
      visit "/admin/user_access_controls?filter%5Buser_id%5D=#{@drill_user.id}"

      # Drill down to the user's full access view in the same app type.
      expected = report_url('user_access_overview_by_role',
                            user: @drill_user.id,
                            app_type_id: @app_type.id)

      expect_link_with_href_including('access overview', expected)
    end

    it 'shows a role-scoped overview link for role-based UACs' do
      visit "/admin/user_access_controls?filter%5Brole_name%5D=#{@role.role_name}"

      expected = report_url('user_access_overview_users_with_role',
                            app_type_id: @app_type.id,
                            role_name: @role.role_name)

      expect_link_with_href_including('users with role', expected)
    end

    it 'shows a resource-scoped overview link when a resource_name is set' do
      # The user-specific UAC is for table/player_infos. The row should
      # provide a "resource grants" link forwarding the app_type, resource_type
      # and resource_name to the resource-focused perspective.
      visit "/admin/user_access_controls?filter%5Bid%5D=#{@uac_user.id}"

      expected = report_url('user_access_overview_resource_by_role',
                            app_type_id: @app_type.id,
                            resource_type: 'table',
                            resource_name: 'player_infos')

      expect_link_with_href_including('resource grants', expected)
    end

    it 'does not show a role-scoped link when no role is set on the UAC' do
      # The user-specific UAC has no role - the row should not include a
      # users-with-role link for that row.
      visit "/admin/user_access_controls?filter%5Bid%5D=#{@uac_user.id}"

      role_link = report_url('user_access_overview_users_with_role',
                             app_type_id: @app_type.id,
                             role_name: '')

      expect_no_link_with_href_including('users with role', role_link)
    end
  end

  describe 'Cross-perspective navigation within User Access Overview reports' do
    before(:each) do
      # Override the admin-only login: cross-perspective tests require
      # a regular user with view_reports access to load report pages.
      Capybara.reset_sessions!
      change_setting('TwoFactorAuthDisabledForUser', true)
      login_as(@report_user, scope: :user)
    end

    it 'shows related-perspective links on each user-centric report, preserving filters' do
      visit report_url('user_access_overview_by_role',
                       user: @drill_user.id,
                       app_type_id: @app_type.id,
                       no_run: 'true')

      panel = find('.uao-related-perspectives', visible: :all)
      links_in_panel = panel.all(:link, visible: :all)
      hrefs = links_in_panel.map { |l| [l.text, l[:href]] }

      by_resource_href = report_url('user_access_overview_by_resource',
                                    user: @drill_user.id,
                                    app_type_id: @app_type.id)
      resolved_href = report_url('user_access_overview_resolved',
                                 user: @drill_user.id,
                                 app_type_id: @app_type.id)

      expect(hrefs).to(
        include(a_collection_including(a_string_matching(/Grants by Resource/i),
                                       a_string_including(by_resource_href))),
        "expected a 'Grants by Resource' link in the related panel. Found: #{hrefs.inspect}"
      )
      expect(hrefs).to(
        include(a_collection_including(a_string_matching(/Effective Access/i),
                                       a_string_including(resolved_href))),
        "expected an 'Effective Access' link in the related panel. Found: #{hrefs.inspect}"
      )
    end

    it 'shows the related-perspective panel on the role-only and users-with-role reports' do
      visit report_url('user_access_overview_roles_only',
                       app_type_id: @app_type.id,
                       no_run: 'true')

      panel = find('.uao-related-perspectives', visible: :all)
      links_in_panel = panel.all(:link, visible: :all)
      hrefs = links_in_panel.map { |l| [l.text, l[:href]] }

      users_with_role_href = report_url('user_access_overview_users_with_role',
                                        app_type_id: @app_type.id)

      expect(hrefs).to(
        include(a_collection_including(a_string_matching(/Each Role's Users/i),
                                       a_string_including(users_with_role_href))),
        "expected an 'Each Role's Users' link in the related panel. Found: #{hrefs.inspect}"
      )
    end
  end
end
