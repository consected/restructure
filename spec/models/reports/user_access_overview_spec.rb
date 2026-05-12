# frozen_string_literal: true

# Purpose: Tests for the User Access Overview seeded admin reports (GitHub Issue #706).
#
# These reports provide five complementary perspectives on a user's effective access controls
# within an app type:
#   Perspective 1 (by_role): UACs grouped by role name or "direct" assignment
#   Perspective 2 (by_resource): UACs grouped by resource, showing which roles granted each
#   Perspective 3 (resolved): One effective UAC per resource after priority_order resolution
#   Perspective 4 (roles_only): User's assigned roles in the selected app type (user optional)
#   Perspective 5 (users_with_role): Users who have a role assigned (user optional)
#
# The tests verify:
#   - All four reports are seeded with correct attributes
#   - Default UAC records are created to gate access to the reports
#   - Each perspective returns expected results given a known set of roles and UACs
#   - Results are correctly scoped by app_type and user
#   - Priority resolution (user-specific > role-based > default) works in Perspective 3
#   - Correct alt_resource_names are set for access gating
#   - The admin index page links to the filtered report list
#   - search_attrs uses select_from_model for app_type_id with default current_user_app_type_id (AC7)
#   - search_attrs uses user type dropdown (label=email, value=user_id) for user selection (AC7)
#   - search_attrs uses select_from_model with group_by for resource_name (AC7)
#   - search_attrs includes role_name filter with select_from_model pointing to admin__user_roles
#   - resource_type config_selector includes filter_selector pointing to resource_name (AC7)
#   - SQL supports optional resource_type, resource_name, and role_name filtering (AC7)
#   - SQL requires user and app_type_id parameters (mandatory criteria)
#   - Result columns contain inline admin links (resource_name, source, role_name, app_scope)
#   - P1 includes user_email column
#   - P4 uses tree view with user email as top level
#   - Column headers include "(role name)" suffix for source columns
#   - Runner nil parameter handling: the report runner converts blank form values to nil,
#     which causes SQL patterns like (:param = '' OR ...) to fail because NULL = '' is NULL (falsy).
#     The NULLIF(:param, '') IS NULL pattern used for :user and :app_type_id handles nil correctly,
#     but :resource_type, :resource_name, and :role_name use the broken (:param = '' OR ...) pattern.

require 'rails_helper'

RSpec.describe 'User Access Overview Reports', type: :model do
  include ModelSupport
  include ReportSupport

  let(:report_short_names) do
    %w[
      user_access_overview_by_role
      user_access_overview_by_resource
      user_access_overview_resolved
      user_access_overview_roles_only
      user_access_overview_users_with_role
    ]
  end

  before :example do
    create_admin
    create_user

    # Run the seed to create/update the reports
    Seeds::ReportUserAccessOverview.setup

    # Create a dedicated app type to avoid collisions with existing seed UACs
    @test_app_type = create_app_type(
      name: "uao_test_#{SecureRandom.hex(4)}",
      label: 'UAO Test App'
    )

    # Grant the user access to the test app type
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      user: @user,
      access: :read,
      resource_type: :general,
      resource_name: :app_type,
      current_admin: @admin
    )

    # Assign roles to the user
    create_user_role 'editor', user: @user, app_type: @test_app_type
    create_user_role 'viewer', user: @user, app_type: @test_app_type

    # Direct (user-specific) UACs
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      user: @user,
      access: :create,
      resource_type: :table,
      resource_name: :player_infos,
      current_admin: @admin
    )
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      user: @user,
      access: :read,
      resource_type: :table,
      resource_name: :trackers,
      current_admin: @admin
    )

    # Role-based UACs for 'editor'
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :update,
      resource_type: :table,
      resource_name: :player_infos,
      role_name: 'editor',
      current_admin: @admin
    )
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :update,
      resource_type: :table,
      resource_name: :trackers,
      role_name: 'editor',
      current_admin: @admin
    )

    # Role-based UACs for 'viewer'
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :read,
      resource_type: :table,
      resource_name: :player_infos,
      role_name: 'viewer',
      current_admin: @admin
    )
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :read,
      resource_type: :general,
      resource_name: :app_type,
      role_name: 'viewer',
      current_admin: @admin
    )

    # Role-based UAC for 'viewer' on addresses (no direct UAC exists for addresses)
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :read,
      resource_type: :table,
      resource_name: :addresses,
      role_name: 'viewer',
      current_admin: @admin
    )

    # Default (fallback) UACs — no user, no role
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :read,
      resource_type: :table,
      resource_name: :trackers,
      current_admin: @admin
    )
    Admin::UserAccessControl.create!(
      app_type: @test_app_type,
      access: :read,
      resource_type: :table,
      resource_name: :addresses,
      current_admin: @admin
    )
  end

  describe 'seed creation' do
    it 'creates all four reports with correct attributes' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        expect(report).to be_present, "Expected report with short_name '#{short_name}' to exist"
        expect(report.disabled).not_to eq true
        expect(report.report_type).to eq 'regular_report'
        expect(report.sql).to be_present
        expect(report.search_attrs).to be_present
      end
    end

    it 'sets correct names for each perspective' do
      expect(Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview').name)
        .to eq("User Access Controls - Selected User's Grants by Role")
      expect(Report.find_by(short_name: 'user_access_overview_by_resource', item_type: 'admin-user-access-overview').name)
        .to eq("User Access Controls - Selected User's Grants by Resource")
      expect(Report.find_by(short_name: 'user_access_overview_resolved', item_type: 'admin-user-access-overview').name)
        .to eq("User Access Controls - Selected User's Effective Access")
      expect(Report.find_by(short_name: 'user_access_overview_roles_only', item_type: 'admin-user-access-overview').name)
        .to eq("User Roles - Each User's Roles")
      expect(Report.find_by(short_name: 'user_access_overview_users_with_role', item_type: 'admin-user-access-overview').name)
        .to eq("User Roles - Each Role's Users")
    end

    it 'creates a resource-focused perspective without changing existing identifiers (issue #1128)' do
      %w[
        user_access_overview_by_role
        user_access_overview_by_resource
        user_access_overview_resolved
        user_access_overview_roles_only
        user_access_overview_users_with_role
      ].each do |short_name|
        existing = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        expect(existing).to be_present, "Expected existing report '#{short_name}' to remain unchanged"
      end

      new_report = Report.find_by(
        short_name: 'user_access_overview_resource_by_role',
        item_type: 'admin-user-access-overview'
      )
      expect(new_report).to be_present,
                             "Expected resource-focused report 'user_access_overview_resource_by_role' to exist"
    end

    it 'includes search_attrs with app_type_id and user for all reports' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        expect(report.search_attrs).to include('app_type_id')
        expect(report.search_attrs).to include('user'),
                                       "Expected search_attrs to include 'user' key in '#{short_name}'"
      end
    end

    it 'uses user type for user search attribute' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        attrs = YAML.safe_load(report.search_attrs)

        expect(attrs).to have_key('user'),
                         "Expected search_attrs to have 'user' key in '#{short_name}'"
        expect(attrs['user']).to have_key('user'),
                                 "Expected 'user' attr to have type 'user' in '#{short_name}'"

        user_config = attrs['user']['user']
        expect(user_config['multiple']).to eq('single'),
                                           "Expected user multiple to be 'single' in '#{short_name}'"
      end
    end

    it 'uses select_from_model for app_type_id with default current_user_app_type_id' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        attrs = YAML.safe_load(report.search_attrs)

        expect(attrs['app_type_id']).to have_key('select_from_model'),
                                        "Expected app_type_id to use select_from_model in '#{short_name}'"
        expect(attrs['app_type_id']).not_to have_key('config_selector'),
                                            "Expected app_type_id NOT to use config_selector in '#{short_name}'"

        sfm = attrs['app_type_id']['select_from_model']
        expect(sfm['resource_name']).to eq('admin__app_types')
        expect(sfm['multiple']).to eq('single')
        expect(sfm['default']).to eq('{{current_user_app_type_id}}'),
                                  "Expected app_type_id to default to current_user_app_type_id in '#{short_name}'"
      end
    end

    it 'includes optional resource_type (config_selector) and resource_name (select_from_model with group_by) filter fields' do
      # Only P1-P3 have resource_type and resource_name filters; P4/P5 use simplified search_attrs
      reports_with_resource_filters = %w[
        user_access_overview_by_role
        user_access_overview_by_resource
        user_access_overview_resolved
      ]

      reports_with_resource_filters.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        attrs = YAML.safe_load(report.search_attrs)

        # resource_type should be a config_selector with all: true
        expect(attrs).to have_key('resource_type'),
                         "Expected search_attrs to include resource_type in '#{short_name}'"
        rt = attrs['resource_type']
        expect(rt).to have_key('config_selector'),
                      "Expected resource_type to use config_selector in '#{short_name}'"
        expect(rt['config_selector']['all']).to eq(true),
                                                "Expected resource_type config_selector to have all: true in '#{short_name}'"

        # Verify the expected selection values are present
        selections = rt['config_selector']['selections']
        %w[table general limited_access report standalone_page activity_log_type].each do |val|
          expect(selections.values).to include(val),
                                       "Expected resource_type selections to include '#{val}' in '#{short_name}'"
        end

        # resource_type config_selector should include filter_selector pointing to resource_name
        expect(rt['config_selector']['filter_selector']).to eq('resource_name'),
                                                            "Expected resource_type config_selector to have filter_selector: resource_name in '#{short_name}'"

        # resource_name should be select_from_model with group_by
        expect(attrs).to have_key('resource_name'),
                         "Expected search_attrs to include resource_name in '#{short_name}'"
        rn = attrs['resource_name']
        expect(rn).to have_key('select_from_model'),
                      "Expected resource_name to use select_from_model in '#{short_name}'"

        sfm = rn['select_from_model']
        expect(sfm['resource_name']).to eq('admin__user_access_controls'),
                                        "Expected resource_name select_from_model resource_name to be 'admin__user_access_controls' in '#{short_name}'"
        expect(sfm['selections']).to eq({ 'resource_name' => 'resource_name' }),
                                     "Expected resource_name selections to map resource_name in '#{short_name}'"
        expect(sfm['group_by']).to eq('resource_type'),
                                   "Expected resource_name select_from_model to have group_by: resource_type in '#{short_name}'"
        expect(sfm['all']).to eq(true),
                              "Expected resource_name select_from_model to have all: true in '#{short_name}'"
      end
    end

    it 'includes role_name filter in search_attrs with select_from_model' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        attrs = YAML.safe_load(report.search_attrs)

        expect(attrs).to have_key('role_name'),
                         "Expected search_attrs to include role_name in '#{short_name}'"

        rn = attrs['role_name']
        expect(rn).to have_key('select_from_model'),
                      "Expected role_name to use select_from_model in '#{short_name}'"

        sfm = rn['select_from_model']
        expect(sfm['resource_name']).to eq('admin__user_roles'),
                                        "Expected role_name select_from_model resource_name to be 'admin__user_roles' in '#{short_name}'"
        expect(sfm['all']).to eq(true),
                              "Expected role_name select_from_model to have all: true in '#{short_name}'"
      end
    end

    it 'includes column headers with role name suffix for source columns' do
      %w[user_access_overview_by_role user_access_overview_by_resource].each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        options = YAML.safe_load(report.options)
        col_opts = options['column_options']
        alt_headers = col_opts&.dig('alt_column_header') || {}

        expect(alt_headers['source']).to include('(role name)'),
                                         "Expected source alt_column_header to include '(role name)' in '#{short_name}'"
      end

      resolved_report = Report.find_by(short_name: 'user_access_overview_resolved', item_type: 'admin-user-access-overview')
      options = YAML.safe_load(resolved_report.options)
      col_opts = options['column_options']
      alt_headers = col_opts&.dig('alt_column_header') || {}

      expect(alt_headers['source']).to include('(role name)'),
                                       "Expected source alt_column_header to include '(role name)' in resolved report"
    end

    it 'sets a consistent position order for the seeded reports (issues #1124, #1128)' do
      expected_order = %w[
        user_access_overview_by_role
        user_access_overview_by_resource
        user_access_overview_resolved
        user_access_overview_resource_by_role
        user_access_overview_roles_only
        user_access_overview_users_with_role
      ]

      positions = expected_order.map do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        [short_name, report.position]
      end

      # Each report has an assigned position
      positions.each do |short_name, position|
        expect(position).to be_present, "Expected report '#{short_name}' to have a position set"
      end

      # Positions are unique
      position_values = positions.map(&:last)
      expect(position_values).to eq(position_values.uniq),
                                 "Expected unique positions, got: #{position_values}"

      # Ordering reports by position yields the expected sequence
      ordered_short_names = Report
                            .where(item_type: 'admin-user-access-overview', short_name: expected_order)
                            .order(position: :asc)
                            .pluck(:short_name)
      expect(ordered_short_names).to eq(expected_order)
    end

    # Issue #1124 - search criteria field labels must indicate required vs
    # optional inputs so admins can use each report without trial and error.
    describe 'search criteria labels (issue #1124)' do
      # Helper to load the configured label for a search attribute key
      def label_for(report, attr_key)
        config = report.search_attributes_config[attr_key.to_sym]
        config&.label
      end

      let(:resource_reports) do
        %w[
          user_access_overview_by_role
          user_access_overview_by_resource
          user_access_overview_resolved
        ]
      end

      let(:role_reports) do
        %w[
          user_access_overview_roles_only
          user_access_overview_users_with_role
        ]
      end

      it 'marks user and app_type_id as required in the first three reports' do
        resource_reports.each do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          expect(label_for(report, :user)).to match(/required/i),
                                              "Expected 'user' label to indicate required in '#{short_name}'"
          expect(label_for(report, :app_type_id)).to match(/required/i),
                                                     "Expected 'app_type_id' label to indicate required in '#{short_name}'"
        end
      end

      it 'marks resource_type, resource_name, and role_name as optional in the first three reports' do
        resource_reports.each do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          expect(label_for(report, :resource_type)).to match(/optional/i),
                                                       "Expected 'resource_type' label to indicate optional in '#{short_name}'"
          expect(label_for(report, :resource_name)).to match(/optional/i),
                                                       "Expected 'resource_name' label to indicate optional in '#{short_name}'"
          expect(label_for(report, :role_name)).to match(/optional/i),
                                                   "Expected 'role_name' label to indicate optional in '#{short_name}'"
        end
      end

      it 'marks app_type_id as required in the roles-by-user and users-by-role reports' do
        role_reports.each do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          expect(label_for(report, :app_type_id)).to match(/required/i),
                                                     "Expected 'app_type_id' label to indicate required in '#{short_name}'"
        end
      end

      it 'marks user and role_name as optional in the roles-by-user and users-by-role reports' do
        role_reports.each do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          expect(label_for(report, :user)).to match(/optional/i),
                                              "Expected 'user' label to indicate optional in '#{short_name}'"
          expect(label_for(report, :role_name)).to match(/optional/i),
                                                   "Expected 'role_name' label to indicate optional in '#{short_name}'"
        end
      end

      it 'uses consistent required/optional label copy across all five reports' do
        # The exact label strings must match across reports for the same
        # required/optional designation, so admins see consistent copy.
        required_user_labels = resource_reports.map do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          label_for(report, :user)
        end
        expect(required_user_labels.uniq.length).to eq(1),
                                                    "Expected consistent required 'user' label, got: #{required_user_labels.uniq}"

        all_reports = resource_reports + role_reports
        app_type_labels = all_reports.map do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          label_for(report, :app_type_id)
        end
        expect(app_type_labels.uniq.length).to eq(1),
                                               "Expected consistent required 'app_type_id' label across all reports, got: #{app_type_labels.uniq}"

        optional_role_labels = (resource_reports + role_reports).map do |short_name|
          report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
          label_for(report, :role_name)
        end
        expect(optional_role_labels.uniq.length).to eq(1),
                                                    "Expected consistent optional 'role_name' label across all reports, got: #{optional_role_labels.uniq}"
      end
    end
  end

  describe 'UAC seed records' do
    it 'creates default UAC records for each report' do
      report_short_names.each do |short_name|
        alt_name = "admin_user_access_overview__#{short_name}"
        uac = Admin::UserAccessControl.active.find_by(
          resource_type: 'report',
          resource_name: alt_name
        )
        expect(uac).to be_present,
                       "Expected a UAC with resource_name '#{alt_name}' for report '#{short_name}'"
      end

      resource_focus_uac = Admin::UserAccessControl.active.find_by(
        resource_type: 'report',
        resource_name: 'admin_user_access_overview__user_access_overview_resource_by_role'
      )
      expect(resource_focus_uac).to be_present,
                                     "Expected a UAC with resource_name 'admin_user_access_overview__user_access_overview_resource_by_role'"
    end
  end

  describe 'alt_resource_names' do
    it 'follows the <item_type_underscored>__<short_name> pattern for all reports' do
      report_short_names.each do |short_name|
        report = Report.find_by(short_name: short_name, item_type: 'admin-user-access-overview')
        expect(report.alt_resource_name).to eq("admin_user_access_overview__#{short_name}")
      end

      resource_focus = Report.find_by(
        short_name: 'user_access_overview_resource_by_role',
        item_type: 'admin-user-access-overview'
      )
      expect(resource_focus.alt_resource_name)
        .to eq('admin_user_access_overview__user_access_overview_resource_by_role')
    end
  end

  describe 'Perspective 1 — by role' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview') }

    it 'returns results for the given user and app type' do
      results = run_report_sql(report)
      expect(results.count).to be > 0
    end

    it 'groups UACs under role names and direct assignments' do
      results = run_report_sql(report)
      sources = results.map { |r| r['source'] || r['id0'] }.uniq

      # Should contain direct, editor, viewer, and default groupings
      expect(sources).to include(a_string_matching(/direct/i))
      expect(sources).to include(a_string_matching(/editor/))
      expect(sources).to include(a_string_matching(/viewer/))
    end

    it 'includes default fallback UACs' do
      results = run_report_sql(report)
      sources = results.map { |r| r['source'] || r['id0'] }.uniq

      expect(sources).to include(a_string_matching(/default/i))
    end

    it 'includes the correct resource details in each row' do
      results = run_report_sql(report)
      fields = results.first.keys

      expect(fields).to include('resource_type')
      expect(fields).to include('resource_name')
      expect(fields).to include('access')
    end

    it 'includes resource_name cells with admin UAC link format' do
      results = run_report_sql(report)

      results.each do |row|
        expect(row['resource_name']).to match(%r{\[.+\]\(/admin/user_access_controls\?filter}),
                                        "Expected resource_name to contain admin UAC link, got: #{row['resource_name']}"
      end
    end

    it 'includes user_email column' do
      results = run_report_sql(report)
      fields = results.first.keys

      expect(fields).to include('user_email'),
                        'Expected P1 results to include a user_email column'
    end

    it 'includes source cells with admin user_roles links for role-based entries' do
      results = run_report_sql(report)

      role_rows = results.select { |r| r['source']&.match?(/editor|viewer/) }
      expect(role_rows).not_to be_empty, 'Expected some role-based rows'

      role_rows.each do |row|
        expect(row['source']).to match(%r{\[.+\]\(/admin/user_roles\?filter\[role_name\]=}),
                                 "Expected source to contain user_roles link, got: #{row['source']}"
      end
    end
  end

  describe 'Perspective 2 — by resource' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_by_resource', item_type: 'admin-user-access-overview') }

    it 'returns results for the given user and app type' do
      results = run_report_sql(report)
      expect(results.count).to be > 0
    end

    it 'groups by resource showing which roles granted each' do
      results = run_report_sql(report)

      # player_infos should appear with multiple sources (direct, editor, viewer, default)
      pi_rows = results.select { |r| r['resource_name']&.include?('player_infos') }
      sources = pi_rows.map { |r| r['source'] }.compact
      expect(sources.length).to be >= 2
    end

    it 'includes resource_type, resource_name, and access in grouping' do
      results = run_report_sql(report)
      fields = results.first.keys

      expect(fields).to include('resource_type')
      expect(fields).to include('resource_name')
      expect(fields).to include('access')
      expect(fields).to include('source')
    end
  end

  describe 'Perspective 3 — resolved' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_resolved', item_type: 'admin-user-access-overview') }

    it 'returns results for the given user and app type' do
      results = run_report_sql(report)
      expect(results.count).to be > 0
    end

    it 'returns exactly one row per resource_type + resource_name combination' do
      results = run_report_sql(report)

      resource_keys = results.map { |r| [r['resource_type'], r['resource_name']] }
      expect(resource_keys).to eq(resource_keys.uniq),
                               'Expected one resolved row per resource but found duplicates'
    end

    it 'resolves user-specific UAC over role-based for player_infos' do
      results = run_report_sql(report)

      pi_row = results.find { |r| r['resource_type'] == 'table' && r['resource_name']&.include?('player_infos') }
      expect(pi_row).to be_present

      # The direct (user-specific) UAC with access=create should win over role-based and default
      expect(pi_row['access']).to eq('create')
      expect(pi_row['source']).to match(/direct/i)
    end

    it 'resolves direct UAC for general/app_type' do
      results = run_report_sql(report)

      # general/app_type has a direct UAC (from create_user setup) — it should win
      app_type_row = results.find { |r| r['resource_type'] == 'general' && r['resource_name']&.include?('app_type') }
      expect(app_type_row).to be_present
      expect(app_type_row['source']).to match(/direct/i)
    end

    it 'resolves role-based UAC over default for resources with no direct UAC' do
      results = run_report_sql(report)

      # addresses has role-based (viewer) + default, but no direct UAC
      addresses_row = results.find { |r| r['resource_type'] == 'table' && r['resource_name']&.include?('addresses') }
      expect(addresses_row).to be_present
      expect(addresses_row['source']).to include('viewer')
    end

    it 'includes resource_name cells with admin UAC link format' do
      results = run_report_sql(report)

      results.each do |row|
        expect(row['resource_name']).to match(%r{\[.+\]\(/admin/user_access_controls\?filter}),
                                        "Expected resource_name to contain admin UAC link, got: #{row['resource_name']}"
      end
    end

    it 'uses tree view grouped by resource_type' do
      report_record = Report.find_by(short_name: 'user_access_overview_resolved', item_type: 'admin-user-access-overview')
      options = YAML.safe_load(report_record.options)
      view_options = options['view_options']

      expect(view_options['view_as']).to eq('tree'),
                                         'Expected P3 to use tree view'
      expect(options).to have_key('tree_view_options'),
                         'Expected P3 to have tree_view_options'
    end

    it 'includes id0 and id1 columns for tree grouping' do
      results = run_report_sql(report)
      fields = results.first.keys

      expect(fields).to include('id0'),
                        'Expected P3 results to include id0 for tree grouping'
      expect(fields).to include('id1'),
                        'Expected P3 results to include id1 for tree row identity'
    end
  end

  describe 'Perspective 6 — resource-focused by role/source (issue #1128)' do
    let(:report) do
      Report.find_by(
        short_name: 'user_access_overview_resource_by_role',
        item_type: 'admin-user-access-overview'
      )
    end

    it 'defines search criteria for app type, resource type, and resource name' do
      expect(report).to be_present,
                        'Expected resource-focused report to exist before validating search_attrs'

      attrs = YAML.safe_load(report.search_attrs)

      expect(attrs).to have_key('app_type_id')
      expect(attrs).to have_key('resource_type')
      expect(attrs).to have_key('resource_name')
    end

    it 'groups by resource and labels source as direct, role-based, or default' do
      expect(report).to be_present,
                        'Expected resource-focused report to exist before validating grouping'

      results = run_report_sql(report, resource_type: 'table', resource_name: 'trackers')
      expect(results).not_to be_empty,
                             'Expected rows for table/trackers in resource-focused perspective'

      # Primary grouping is by resource (id0 = resource_type / resource_name)
      id0_values = results.map { |r| r['id0'] }.uniq
      expect(id0_values).to all(include('trackers')),
                            "Expected id0 to group rows by resource (trackers), got: #{id0_values}"

      # Source column carries short, distinct category labels — not the role name itself
      sources = results.map { |r| r['source'].to_s }
      expect(sources).to include(a_string_matching(/direct/i)),
                         'Expected a direct user-specific source label'
      expect(sources).to include(a_string_matching(/default|fallback/i)),
                         'Expected a default/fallback source label'
      expect(sources).to include(a_string_matching(/role-based/i)),
                         'Expected a role-based source label'

      # Role-based rows must carry the role link in role_name (not duplicated in source)
      role_rows = results.select { |r| r['source'].to_s.match?(/role-based/i) }
      expect(role_rows).not_to be_empty
      role_rows.each do |row|
        expect(row['role_name']).to match(%r{\[.+\]\(/admin/user_roles}),
                                    "Expected role_name to carry the role link, got: #{row['role_name']}"
        expect(row['source']).not_to match(%r{/admin/user_roles}),
                                     "Expected source not to duplicate the role link, got: #{row['source']}"
      end
    end

    it 'returns access, scope, user/role, resource type and resource name columns' do
      expect(report).to be_present,
                        'Expected resource-focused report to exist before validating columns'

      results = run_report_sql(report, resource_type: 'table', resource_name: 'trackers')
      expect(results).not_to be_empty

      fields = results.first.keys
      expect(fields).to include('access')
      expect(fields).to include('app_scope')
      expect(fields).to include('user_email')
      expect(fields).to include('role_name')
      expect(fields).to include('resource_type')
      expect(fields).to include('resource_name')
    end

    it 'applies app type, resource type and resource name filters to the selected resource' do
      expect(report).to be_present,
                        'Expected resource-focused report to exist before validating filters'

      results = run_report_sql(report, resource_type: 'table', resource_name: 'trackers')
      expect(results).not_to be_empty

      results.each do |row|
        expect(row['resource_type']).to eq('table')
        expect(row['resource_name']).to include('trackers')
      end
    end
  end

  describe 'Perspective 4 — roles only' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_roles_only', item_type: 'admin-user-access-overview') }

    it 'returns results for the given user and app type' do
      results = run_report_sql(report)
      expect(results.count).to be > 0
    end

    it 'lists the assigned roles for the user' do
      results = run_report_sql(report)
      role_names = results.map { |r| r['role_name'] }

      expect(role_names).to include(a_string_matching(/editor/))
      expect(role_names).to include(a_string_matching(/viewer/))
    end

    it 'does not include roles from other users' do
      original_user = @user
      other_user, = create_user('other')
      create_user_role 'other_role', user: other_user, app_type: @test_app_type

      # Restore original user for the report query
      @user = original_user

      # Re-run with original user
      results = run_report_sql(report)
      role_names = results.map { |r| r['role_name'] }

      expect(role_names).not_to include(a_string_matching(/other_role/))
    end

    it 'includes role_name cells with admin user_roles link format' do
      results = run_report_sql(report)

      results.each do |row|
        expect(row['role_name']).to match(%r{\[.+\]\(/admin/user_roles\?filter\[role_name\]=}),
                                    "Expected role_name to contain user_roles link, got: #{row['role_name']}"
      end
    end

    it 'uses tree view with user email as top level' do
      report_record = Report.find_by(short_name: 'user_access_overview_roles_only', item_type: 'admin-user-access-overview')
      options = YAML.safe_load(report_record.options)
      view_options = options['view_options']

      expect(view_options['view_as']).to eq('tree'),
                                         'Expected P4 to use tree view'
      expect(options).to have_key('tree_view_options'),
                         'Expected P4 to have tree_view_options'
    end

    it 'includes user_email and id0 columns for tree grouping' do
      results = run_report_sql(report)
      fields = results.first.keys

      expect(fields).to include('id0'),
                        'Expected P4 results to include id0 for tree grouping'
      expect(fields).to include('user_email'),
                        'Expected P4 results to include user_email column'
    end

    it 'returns results when user is blank (user is optional)' do
      results = run_report_sql(report, user: '')
      expect(results).not_to be_empty,
                             'Expected P4 to return results when user is blank (optional)'
    end

    it 'returns no results when app_type_id is blank (app_type_id is mandatory)' do
      results = run_report_sql(report, app_type_id: '')
      expect(results).to be_empty,
                         'Expected P4 to return no results when app_type_id is blank (mandatory)'
    end
  end

  describe 'Perspective 5 — users with role' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_users_with_role', item_type: 'admin-user-access-overview') }

    it 'exists and has correct attributes' do
      expect(report).to be_present, "Expected report with short_name 'user_access_overview_users_with_role' to exist"
      expect(report.disabled).not_to eq true
      expect(report.report_type).to eq 'regular_report'
    end

    it 'returns results for the given app type' do
      results = run_report_sql(report, user: '')
      expect(results.count).to be > 0
    end

    it 'lists users and their assigned roles in the app type' do
      results = run_report_sql(report, user: '')

      # Should include our test user's roles
      user_emails = results.map { |r| r['user_email'] }
      expect(user_emails).to include(a_string_matching(/@/)),
                             'Expected users_with_role results to include user emails'

      role_names = results.map { |r| r['role_name'] }
      expect(role_names).to include(a_string_matching(/editor/))
      expect(role_names).to include(a_string_matching(/viewer/))
    end

    it 'groups by role_name with user details in child rows' do
      report_record = Report.find_by(short_name: 'user_access_overview_users_with_role', item_type: 'admin-user-access-overview')
      options = YAML.safe_load(report_record.options)
      view_options = options['view_options']

      expect(view_options['view_as']).to eq('tree'),
                                         'Expected P5 to use tree view'
      expect(options).to have_key('tree_view_options'),
                         'Expected P5 to have tree_view_options'
    end

    it 'returns results when user is blank (user is optional)' do
      results = run_report_sql(report, user: '')
      expect(results).not_to be_empty,
                             'Expected P5 to return results when user is blank'
    end

    it 'returns no results when app_type_id is blank (app_type_id is mandatory)' do
      results = run_report_sql(report, app_type_id: '')
      expect(results).to be_empty,
                         'Expected P5 to return no results when app_type_id is blank'
    end

    it 'filters by user when provided' do
      original_user = @user
      other_user, = create_user('p5other')
      create_user_role 'p5only_role', user: other_user, app_type: @test_app_type

      # Restore original user for the report query
      @user = original_user

      # With our test user, should not see p5only_role
      results = run_report_sql(report)
      role_names = results.map { |r| r['role_name'] }
      expect(role_names).not_to include(a_string_matching(/p5only_role/))
    end

    it 'filters by role_name when provided' do
      results = run_report_sql(report, user: '', role_name: 'editor')

      results.each do |row|
        expect(row['role_name']).to include('editor'),
                                    "Expected role_name to include 'editor', got: #{row['role_name']}"
      end
    end

    it 'includes role_name and user_email cells with admin links' do
      results = run_report_sql(report, user: '')

      results.each do |row|
        expect(row['role_name']).to match(%r{\[.+\]\(/admin/user_roles\?filter\[role_name\]=}),
                                    "Expected role_name link, got: #{row['role_name']}"
        expect(row['user_email']).to match(%r{\[.+\]\(/admin/manage_users\?filter\[email\]=}),
                                     "Expected user_email link, got: #{row['user_email']}"
      end
    end
  end

  describe 'filtering' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview') }

    it 'scopes results to the specified app_type' do
      other_app_type = create_app_type(name: "other_app_#{SecureRandom.hex(4)}", label: 'Other App')

      # Create a UAC in the other app type
      Admin::UserAccessControl.create!(
        app_type: other_app_type,
        user: @user,
        access: :read,
        resource_type: :table,
        resource_name: :addresses,
        current_admin: @admin
      )

      # Results for the test app_type should not include UACs from other_app_type
      # (the user-specific address UAC is in other_app_type, not test_app_type)
      results = run_report_sql(report)
      direct_address_rows = results.select do |r|
        r['resource_name']&.include?('addresses') && r['source']&.match?(/direct/i)
      end
      expect(direct_address_rows).to be_empty
    end

    it 'scopes results to the specified user' do
      original_user = @user
      other_user, = create_user('filtered')
      create_user_role 'editor', user: other_user, app_type: @test_app_type

      Admin::UserAccessControl.create!(
        app_type: @test_app_type,
        user: other_user,
        access: :read,
        resource_type: :table,
        resource_name: :pro_infos,
        current_admin: @admin
      )

      # Restore original user for the report query
      @user = original_user

      # Results for original user should not include UACs specific to other_user
      results = run_report_sql(report)
      direct_pro_info_rows = results.select do |r|
        r['resource_name']&.include?('pro_infos') && r['source']&.match?(/direct/i)
      end
      expect(direct_pro_info_rows).to be_empty
    end
  end

  describe 'optional resource filters' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview') }

    it 'filters results by resource_type when provided' do
      # Without filter, we should get multiple resource_types (table and general)
      all_results = run_report_sql(report)
      all_types = all_results.map { |r| r['resource_type'] }.uniq
      expect(all_types.length).to be > 1,
                                  'Precondition: expected multiple resource_types without filter'

      # With resource_type = 'table', only table resources should appear
      filtered_results = run_report_sql(report, resource_type: 'table')
      filtered_types = filtered_results.map { |r| r['resource_type'] }.uniq

      expect(filtered_types).to eq(['table']),
                                "Expected only 'table' resources, got: #{filtered_types}"
      expect(filtered_results.count).to be < all_results.count,
                                        'Expected fewer results when filtering by resource_type'
    end

    it 'filters results by resource_name when provided' do
      # Without filter, we should get multiple resource_names
      all_results = run_report_sql(report)
      all_names = all_results.map { |r| r['resource_name'] }.uniq
      expect(all_names.length).to be > 1,
                                  'Precondition: expected multiple resource_names without filter'

      # With resource_name = 'player_infos', only matching resources should appear
      filtered_results = run_report_sql(report, resource_name: 'player_infos')

      filtered_results.each do |r|
        expect(r['resource_name']).to include('player_infos'),
                                      "Expected resource_name to include 'player_infos', got: #{r['resource_name']}"
      end
      expect(filtered_results.count).to be < all_results.count,
                                        'Expected fewer results when filtering by resource_name'
    end

    it 'returns all results when resource_type and resource_name are blank' do
      all_results = run_report_sql(report)
      blank_filter_results = run_report_sql(report, resource_type: '', resource_name: '')

      expect(blank_filter_results.count).to eq(all_results.count),
                                            'Expected blank filters to return same results as no filters'
    end

    it 'combines resource_type and resource_name filters' do
      filtered_results = run_report_sql(report, resource_type: 'table', resource_name: 'player_infos')

      filtered_results.each do |row|
        expect(row['resource_type']).to eq('table')
        expect(row['resource_name']).to include('player_infos')
      end

      expect(filtered_results.count).to be > 0,
                                        'Expected at least one result for table/player_infos'
    end

    it 'returns no results when user and app_type_id are blank (mandatory)' do
      # user and app_type_id are now mandatory — blank values should return empty results
      results = run_report_sql(report, user: '', app_type_id: '')
      expect(results).to be_empty,
                         'Expected no results when mandatory user and app_type_id are blank'
    end

    it 'filters results by role_name when provided' do
      all_results = run_report_sql(report)

      # With role_name = 'editor', only role-based UACs for 'editor' should appear
      filtered_results = run_report_sql(report, role_name: 'editor')

      expect(filtered_results.count).to be > 0,
                                        'Expected at least one result when filtering by role_name=editor'
      expect(filtered_results.count).to be < all_results.count,
                                        'Expected fewer results when filtering by role_name'

      filtered_results.each do |row|
        expect(row['source']).to include('editor'),
                                 "Expected source to reference 'editor' when filtering by role_name, got: #{row['source']}"
      end
    end
  end

  describe 'runner nil parameter handling' do
    # The report runner's search_attrs_prep converts blank form values to nil.
    # sanitize_sql_for_conditions then renders nil as NULL in the SQL.
    # user and app_type_id are now mandatory — nil/blank values return empty results.
    # resource_type, resource_name, and role_name remain optional and use COALESCE.

    it 'P1 (by_role): returns empty when user and app_type_id are nil' do
      report = Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil, app_type_id: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).to be_empty,
                         'Expected P1 to return no results when mandatory user/app_type_id are nil'
    end

    it 'P2 (by_resource): returns empty when user and app_type_id are nil' do
      report = Report.find_by(short_name: 'user_access_overview_by_resource', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil, app_type_id: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).to be_empty,
                         'Expected P2 to return no results when mandatory user/app_type_id are nil'
    end

    it 'P3 (resolved): returns empty when user and app_type_id are nil' do
      report = Report.find_by(short_name: 'user_access_overview_resolved', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil, app_type_id: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).to be_empty,
                         'Expected P3 to return no results when mandatory user/app_type_id are nil'
    end

    it 'P4 (roles_only): returns results when user is nil but app_type_id is valid' do
      report = Report.find_by(short_name: 'user_access_overview_roles_only', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).not_to be_empty,
                             'Expected P4 to return results when app_type_id is valid but user is nil'
    end

    it 'P4 (roles_only): returns empty when app_type_id is nil' do
      report = Report.find_by(short_name: 'user_access_overview_roles_only', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil, app_type_id: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).to be_empty,
                         'Expected P4 to return no results when mandatory app_type_id is nil'
    end

    it 'P5 (users_with_role): returns results when user is nil but app_type_id is valid' do
      report = Report.find_by(short_name: 'user_access_overview_users_with_role', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).not_to be_empty,
                             'Expected P5 to return results when app_type_id is valid but user is nil'
    end

    it 'P5 (users_with_role): returns empty when app_type_id is nil' do
      report = Report.find_by(short_name: 'user_access_overview_users_with_role', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: nil, app_type_id: nil,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).to be_empty,
                         'Expected P5 to return no results when mandatory app_type_id is nil'
    end

    it 'P1: returns results when only resource filters are nil' do
      report = Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview')
      results = run_report_sql(report, user: @user.id.to_s, app_type_id: @test_app_type.id.to_s,
                                       resource_type: nil, resource_name: nil, role_name: nil)
      expect(results).not_to be_empty,
                             'Expected P1 to return results with valid user/app_type but nil resource filters'
    end
  end

  describe 'ordering' do
    let(:report) { Report.find_by(short_name: 'user_access_overview_by_role', item_type: 'admin-user-access-overview') }

    it 'groups results by id0 (source category)' do
      results = run_report_sql(report)
      id0_values = results.map { |r| r['id0'] }

      # id0 values should be grouped (consecutive identical values)
      # Each category should appear in a contiguous block
      categories = id0_values.chunk { |v| v }.map(&:first)
      expect(categories.length).to be >= 2,
                                   'Expected at least two distinct source categories'

      # Should contain direct, role, and default categories
      expect(id0_values).to include(a_string_matching(/direct/i))
      expect(id0_values).to include(a_string_matching(/default/i))
    end
  end

  describe 'P0 landing page report removal' do
    it 'disables the old landing page report if it exists' do
      # The seed should disable any existing P0 report
      report = Report.find_by(short_name: 'user_access_overview')
      if report
        expect(report.disabled).to eq(true),
                                   'Expected old P0 landing page report to be disabled'
      end
    end
  end

  describe 'admin index page link' do
    it 'links to the filtered report list for user access overview' do
      template_path = Rails.root.join('app/views/pages/_index_admin.html.erb')
      template_content = File.read(template_path)

      # Find the line(s) that contain the User Access Overview link
      overview_lines = template_content.lines.select { |line| line.include?('User Access Overview') }
      expect(overview_lines).not_to be_empty, 'Expected a User Access Overview link in the admin index'

      overview_line = overview_lines.first

      # Should link to filtered report list, not a specific report
      expect(overview_line).to include('admin-user-access-overview'),
                               'Expected the admin index link to filter by item_type admin-user-access-overview'

      # The link line must still be gated by both :user_roles AND :user_access_controls
      expect(overview_line).to include('can_admin?(:user_roles)'),
                               'Expected the overview link to require :user_roles capability'
      expect(overview_line).to include('can_admin?(:user_access_controls)'),
                               'Expected the overview link to require :user_access_controls capability'
    end
  end

  private

  # Execute a report's SQL directly against the database with test parameters.
  # Accepts optional extra_params (e.g. resource_type, resource_name) to test filter clauses.
  def run_report_sql(report, **extra_params)
    raise 'Report not found' unless report

    sql = report.sql
    params = {
      app_type_id: @test_app_type.id.to_s,
      user: @user.id.to_s,
      resource_type: '',
      resource_name: '',
      role_name: ''
    }.merge(extra_params)
    sanitized = ActiveRecord::Base.sanitize_sql_for_conditions([sql, params])
    ActiveRecord::Base.connection.execute(sanitized).to_a
  end
end
