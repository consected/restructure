# frozen_string_literal: true

# Report Embedded Block System Spec
#
# Tests the embedded_block feature in reports that displays dynamic model and activity log
# records in a modal dialog when clicked. This is a UI test that verifies the full interaction.
#
# Test Coverage:
# - Dynamic Models:
#   - Show URL opens modal in show mode (uses JSON + client-side Handlebars templates)
#   - Edit URL (ending in /edit) opens modal in edit mode (GitHub #325)
#   - When edit mode modal is saved, the modal closes automatically
# - Activity Logs:
#   - Edit URL (ending in /edit) opens modal in edit mode (GitHub #325)
#   - Note: Show mode not tested for activity logs as Handlebars templates aren't loaded on report pages

require 'rails_helper'

describe 'report embedded_block', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include TestFieldsDmSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    seed_database
    create_data_set_outside_tx

    setup_test_user
    setup_dynamic_model
    setup_test_data
    setup_reports
  end

  #
  # Setup helpers
  #
  def setup_test_user
    @user, @good_password = create_user
    @good_email = @user.email

    grant_report_access
    grant_model_access
  end

  def grant_report_access
    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @admin,
      user: @user
    )
  end

  def grant_model_access
    setup_access :dynamic_model__test_with_id_recs, user: @user
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user
  end

  def setup_dynamic_model
    setup_fields_dm
    DynamicModel.routes_reload
    Rails.application.routes_reloader.reload!
  end

  def setup_test_data
    @master = Master.create!(current_user: @user)

    @test_record = DynamicModel::TestWithIdRec.create!(
      master: @master,
      name: 'Embedded Block Test Record',
      value: 'Test Value 123',
      current_user: @user
    )

    @player_contact = PlayerContact.create!(
      master: @master,
      data: '(617)555-1234',
      rec_type: 'phone',
      rank: 10,
      current_user: @user
    )

    @activity_log = ActivityLog::PlayerContactPhone.create!(
      master: @master,
      player_contact: @player_contact,
      select_call_direction: 'from player',
      select_who: 'user',
      extra_log_type: 'primary',
      current_user: @user
    )
  end

  def setup_reports
    @report_dm_show = create_embedded_block_report(
      name: 'DM Show Mode',
      sql: dynamic_model_show_sql,
      link_column: 'show_link'
    )

    @report_dm_edit = create_embedded_block_report(
      name: 'DM Edit Mode',
      sql: dynamic_model_edit_sql,
      link_column: 'edit_link'
    )

    @report_al_edit = create_embedded_block_report(
      name: 'AL Edit Mode',
      sql: activity_log_edit_sql,
      link_column: 'al_edit_link'
    )
  end

  def create_embedded_block_report(name:, sql:, link_column:)
    report = Report.create!(
      current_admin: @admin,
      name: "#{name} #{SecureRandom.hex(4)}",
      description: "Test #{name}",
      sql: sql,
      options: "column_options:\n  show_as:\n    #{link_column}: embedded_block",
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: report.alt_resource_name,
      current_admin: @admin
    )

    report
  end

  #
  # SQL generators for reports
  #
  def dynamic_model_show_sql
    <<~SQL
      SELECT '/masters/' || master_id || '/dynamic_model/test_with_id_recs/' || id AS show_link, name
      FROM dynamic_test.test_with_id_recs ORDER BY id DESC LIMIT 1
    SQL
  end

  def dynamic_model_edit_sql
    <<~SQL
      SELECT '/masters/' || master_id || '/dynamic_model/test_with_id_recs/' || id || '/edit' AS edit_link, name
      FROM dynamic_test.test_with_id_recs ORDER BY id DESC LIMIT 1
    SQL
  end

  def activity_log_edit_sql
    <<~SQL
      SELECT '/masters/' || master_id || '/activity_log/player_contact_phones/' || id || '/edit' AS al_edit_link, extra_log_type
      FROM activity_log_player_contact_phones ORDER BY id DESC LIMIT 1
    SQL
  end

  #
  # Navigation and interaction helpers
  #
  before(:each) do
    login
    visit '/reports'
    finish_page_loading
  end

  def navigate_to_report(report)
    visit '/reports'
    finish_page_loading

    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{report.id}']")

    within ".data-results table.tablesorter tr[data-report-id='#{report.id}']" do
      click_link report.name
    end

    expect(page).to have_css('.report-criteria')
    finish_page_loading
  end

  def run_report_and_click_embedded_link
    within('#report_query_form') { click_button 'table' }
    expect(page).to have_css('.search-status-done')
    expect(page).to have_css('.report-results-block table')
    finish_page_loading

    dismiss_all_alerts
    link = find('.report-embedded-block-link')
    scroll_into_view(link)
    sleep 0.5
    link.click
    finish_page_loading
  end

  def wait_for_modal_to_appear
    modal_appeared = false
    5.times do
      sleep 2
      if page.has_css?('#primary-modal1.fade.in', visible: true)
        modal_appeared = true
        break
      end
    end

    unless modal_appeared
      puts_debug 'Modal did not appear - checking for errors'
      puts_debug "Alert: #{find('.alert-danger').text}" if page.has_css?('.alert-danger')
      save_html_snapshot('/tmp/modal_debug.html')
    end

    expect(modal_appeared).to be(true), 'Modal did not appear after multiple retries'
    finish_page_loading
  end

  #
  # Shared examples for common test patterns
  #
  shared_examples 'opens modal with embedded content' do
    it 'displays the modal when clicking embedded_block link' do
      navigate_to_report(report)
      run_report_and_click_embedded_link
      wait_for_modal_to_appear
      expect(page).to have_css('#primary-modal1.fade.in')
    end
  end

  shared_examples 'opens in edit mode' do
    it 'shows the edit form directly' do
      navigate_to_report(report)
      run_report_and_click_embedded_link
      wait_for_modal_to_appear

      within '#primary-modal1.fade.in' do
        expect(page).to have_css(edit_form_selector, wait: 10)
        expect(page).to have_button('Save')
      end
    end
  end

  #
  # Test contexts
  #
  context 'with dynamic model show URL (existing behavior)' do
    let(:report) { @report_dm_show }

    include_examples 'opens modal with embedded content'

    it 'displays record in read-only mode without edit form' do
      navigate_to_report(report)
      run_report_and_click_embedded_link
      wait_for_modal_to_appear

      within '#primary-modal1.fade.in' do
        expect(page).to have_content(/embedded block test record/i)
        expect(page).not_to have_css('form.edit_dynamic_model_test_with_id_rec')
      end
    end
  end

  context 'with dynamic model edit URL (GitHub #325)' do
    let(:report) { @report_dm_edit }
    let(:edit_form_selector) { 'form.edit_dynamic_model_test_with_id_rec' }

    include_examples 'opens modal with embedded content'
    include_examples 'opens in edit mode'

    it 'allows editing and closes modal on save' do
      navigate_to_report(report)
      run_report_and_click_embedded_link
      wait_for_modal_to_appear

      within '#primary-modal1.fade.in' do
        expect(page).to have_css(edit_form_selector, wait: 10)
        fill_in 'dynamic_model_test_with_id_rec[name]', with: 'Updated Record Name'
        click_button 'Save'
      end

      expect(page).not_to have_css('#primary-modal1.fade.in', wait: 10)

      @test_record.reload
      expect(@test_record.name).to eq('updated record name')
    end
  end

  context 'with activity log edit URL (GitHub #325)' do
    let(:report) { @report_al_edit }
    let(:edit_form_selector) { 'form.edit_activity_log_player_contact_phone' }

    include_examples 'opens modal with embedded content'
    include_examples 'opens in edit mode'

    it 'allows editing and closes modal on save' do
      navigate_to_report(report)
      run_report_and_click_embedded_link
      wait_for_modal_to_appear

      within '#primary-modal1.fade.in' do
        expect(page).to have_css(edit_form_selector, wait: 10)
        # Form is already valid from setup, just save it
        click_button 'Save'
      end

      expect(page).not_to have_css('#primary-modal1.fade.in', wait: 10)
    end
  end
end
