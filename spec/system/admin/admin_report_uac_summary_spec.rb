# frozen_string_literal: true

# Admin Report UAC Summary Spec - Issue #1014
#
# Tests that the Reports admin page Definition tab displays a user access controls
# summary section, similar to the dynamic models admin page.
#
# The _def_uac_summary partial should be rendered within the Definition tab
# (id="report-def") of the reports admin panel, showing:
# - A "user access controls" label with a "view all" link
# - A list of UAC entries with role names and access levels
# - A warning when no UACs are defined for the resource
#
# The reports _def_block.html.erb renders the _def_uac_summary partial with
# explicit resource_name and resource_type locals for reports.

require 'rails_helper'

describe 'admin report UAC summary - Issue #1014', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
    # Save admin credentials before create_user overwrites @good_email / @good_password
    @admin_email = @good_email
    @admin_password = @good_password
    create_user

    # Restore admin credentials for admin_sign_in_with_2fa
    @good_email = @admin_email
    @good_password = @admin_password

    # Report WITH a UAC entry
    @report_with_uac = Report.create!(
      current_admin: @admin,
      name: "UAC Summary Test #{SecureRandom.hex(4)}",
      description: 'Test report for UAC summary display',
      sql: 'select id from admins limit 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      position: nil
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @report_with_uac.alt_resource_name,
      current_admin: @admin
    )

    # Report WITHOUT any UAC entries
    @report_without_uac = Report.create!(
      current_admin: @admin,
      name: "No UAC Test #{SecureRandom.hex(4)}",
      description: 'Test report with no UACs defined',
      sql: 'select id from admins limit 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      position: nil
    )
  end

  after(:all) do
    @report_with_uac&.update(disabled: true, current_admin: @admin) if @report_with_uac&.persisted?
    @report_without_uac&.update(disabled: true, current_admin: @admin) if @report_without_uac&.persisted?
  end

  it 'shows UAC summary with entries in the Definition tab for a report with UACs' do
    admin_sign_in_with_2fa

    visit '/admin/reports'
    finish_page_loading

    within "#admin-item-#{@report_with_uac.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # The Definition tab (report-def) is active by default
    expect(page).to have_css('#report-def', wait: 10)
    finish_page_loading

    within '#report-def' do
      expect(page).to have_content('user access controls')
      expect(page).to have_link('view all')
      expect(page).to have_css('.common-def-panel--uacs')
      expect(page).to have_css('.common-def-panel--uacs li', minimum: 1)
    end
  end

  it 'shows a warning when no UACs are defined for the report' do
    admin_sign_in_with_2fa

    visit '/admin/reports'
    finish_page_loading

    within "#admin-item-#{@report_without_uac.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#report-def', wait: 10)
    finish_page_loading

    within '#report-def' do
      expect(page).to have_content('user access controls')
      expect(page).to have_content('No user access controls defined for this resource')
    end
  end
end
