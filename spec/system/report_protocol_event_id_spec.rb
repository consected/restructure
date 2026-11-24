# frozen_string_literal: true

# Ensures protocol, sub-process, and protocol-event names are rendered in an
# auto-run tracker-history report even when protocol-event definitions are not cached.
require 'rails_helper'

describe 'auto-run tracker history report lookup names', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include FeatureSupport
  include MasterSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    @user, @good_password = create_user
    @good_email = @user.email
    setup_access :view_reports, resource_type: :general, access: :read, user: @user

    @master = create_master(@user)
    @protocol = Classification::Protocol.create!(name: "Report protocol #{SecureRandom.hex(4)}", current_admin: @admin)
    @sub_process = @protocol.sub_processes.create!(name: "Report sub-process #{SecureRandom.hex(4)}", current_admin: @admin)
    @protocol_event = @sub_process.protocol_events.create!(name: "Report protocol event #{SecureRandom.hex(4)}", current_admin: @admin)
    @master.trackers.create!(
      protocol_id: @protocol.id,
      sub_process_id: @sub_process.id,
      protocol_event_id: @protocol_event.id,
      event_date: Time.current
    )

    @report = Report.create!(
      current_admin: @admin,
      name: "Issue 1586 auto-run tracker history #{SecureRandom.hex(4)}",
      description: 'Auto-run tracker history report for issue 1586',
      sql: "select protocol_id, sub_process_id, protocol_event_id from tracker_history where master_id = #{@master.id}",
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: true,
      searchable: false,
      position: nil
    )
    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @report.alt_resource_name,
      current_admin: @admin,
      user: @user
    )

    @protocol_name = @protocol.name
    @sub_process_name = @sub_process.name
    @protocol_event_name = @protocol_event.name
  end

  after(:all) do
    @report&.update!(disabled: true, current_admin: @admin) if @report&.persisted?
    @protocol_event&.update!(disabled: true, current_admin: @admin) if @protocol_event&.persisted?
    @sub_process&.update!(disabled: true, current_admin: @admin) if @sub_process&.persisted?
    @protocol&.update!(disabled: true, current_admin: @admin) if @protocol&.persisted?
  end

  before(:each) do
    login
  end

  it 'renders protocol-event names on first auto-run when the lookup definition is uncached' do
    # Protocol and sub-process lookups are available as in an established session,
    # while protocol_events remains cold on the fresh report-page load.
    page.driver.browser.execute_async_script(<<~JS)
      const done = arguments[arguments.length - 1];
      _fpa.cache.get_definition('protocols', function() {
        _fpa.cache.get_definition('sub_processes', done);
      });
    JS
    page.execute_script("localStorage.removeItem(_fpa.cache.cache_name('protocol_events'))")
    expect(page.evaluate_script("_fpa.cache.fetch('protocols')")).not_to be_nil
    expect(page.evaluate_script("_fpa.cache.fetch('sub_processes')")).not_to be_nil
    expect(page.evaluate_script("_fpa.cache.fetch('protocol_events')")).to be_nil

    visit report_path(@report)
    finish_page_loading

    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    expect(page).to have_css("td[data-col-type='protocol_id'] em", text: @protocol_name, wait: 15)
    expect(page).to have_css("td[data-col-type='sub_process_id'] em", text: @sub_process_name, wait: 15)
    expect(page).to have_css("td[data-col-type='protocol_event_id'] em", text: @protocol_event_name, wait: 15)
  end
end
