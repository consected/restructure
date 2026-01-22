# frozen_string_literal: true

# Report Embedded Block System Spec
#
# Tests the embedded_block feature in reports that displays dynamic model and activity log
# records in a modal dialog when clicked. This is a UI test that verifies the full interaction.
#
# Test Coverage:
# - Clicking embedded_block link with show URL opens modal in show mode (existing behavior)
# - Clicking embedded_block link with edit URL (ending in /edit) opens modal in edit mode (GitHub #325)
# - When edit mode modal is saved, the modal should close automatically
# - Works for both dynamic models and activity logs

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

    # Must create user BEFORE setup_fields_dm since it requires @user
    setup_embedded_block_test_user

    setup_fields_dm # Sets up dynamic_model__test_with_id_recs

    # Reload routes after setting up dynamic model
    DynamicModel.routes_reload
    Rails.application.routes_reloader.reload!

    setup_embedded_block_test_data
    setup_embedded_block_reports
  end

  def setup_embedded_block_test_user
    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create!(
      app_type_id: @user.app_type_id,
      access: :read,
      resource_type: :general,
      resource_name: :view_reports,
      current_admin: @admin,
      user: @user
    )

    setup_access :dynamic_model__test_with_id_recs, user: @user

    expect(@user.can?(:view_reports)).to be_truthy
  end

  def setup_embedded_block_test_data
    # Create a test record we can display in embedded_block
    @master = Master.create!(current_user: @user)
    @test_record = DynamicModel::TestWithIdRec.create!(
      master: @master,
      name: 'Embedded Block Test Record',
      value: 'Test Value 123',
      current_user: @user
    )
    expect(@test_record).to be_persisted
  end

  def setup_embedded_block_reports
    # Report with embedded_block using show URL (existing behavior)
    # Dynamic model routes require master_id: /masters/{master_id}/dynamic_model/table_name/{id}
    # Use subquery to get the latest record dynamically
    sql_show = <<~SQL
      SELECT
        '/masters/' || master_id || '/dynamic_model/test_with_id_recs/' || id AS show_link,
        name
      FROM dynamic_test.test_with_id_recs
      ORDER BY id DESC
      LIMIT 1
    SQL

    options_show = <<~YAML
      column_options:
        show_as:
          show_link: embedded_block
    YAML

    @report_show = Report.create!(
      current_admin: @admin,
      name: "Embedded Block Show Mode #{SecureRandom.hex(4)}",
      description: 'Test embedded_block in show mode',
      sql: sql_show,
      options: options_show,
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @report_show.alt_resource_name,
      current_admin: @admin
    )

    # Report with embedded_block using edit URL (new GitHub #325 feature)
    sql_edit = <<~SQL
      SELECT
        '/masters/' || master_id || '/dynamic_model/test_with_id_recs/' || id || '/edit' AS edit_link,
        name
      FROM dynamic_test.test_with_id_recs
      ORDER BY id DESC
      LIMIT 1
    SQL

    options_edit = <<~YAML
      column_options:
        show_as:
          edit_link: embedded_block
    YAML

    @report_edit = Report.create!(
      current_admin: @admin,
      name: "Embedded Block Edit Mode #{SecureRandom.hex(4)}",
      description: 'Test embedded_block in edit mode (GitHub #325)',
      sql: sql_edit,
      options: options_edit,
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )

    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: @report_edit.alt_resource_name,
      current_admin: @admin
    )
  end

  before(:each) do
    login
    # Make sure no modal is open from a previous test
    visit '/reports'
    finish_page_loading
  end

  def navigate_to_report(report)
    # Navigate fresh each time
    visit '/reports'
    finish_page_loading

    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{report.id}']")

    within ".data-results table.tablesorter tr[data-report-id='#{report.id}']" do
      click_link report.name
    end

    expect(page).to have_css('.report-criteria')
    finish_page_loading
  end

  def run_report
    within '#report_query_form' do
      click_button 'table'
    end

    expect(page).to have_css('.search-status-done')
    expect(page).to have_css('.report-results-block table')
    finish_page_loading
  end

  def click_embedded_block_link
    # Clear any flash notices that might obscure the link
    dismiss_all_alerts

    # Find and click the embedded_block link (glyphicon-tasks icon)
    link = find('.report-embedded-block-link')
    scroll_into_view(link)
    sleep 0.5

    # Ensure the link is clickable (not obscured)
    expect(link).to be_visible

    link.click
    finish_page_loading
  end

  def wait_for_modal
    # Allow time for AJAX and modal animation
    # Sometimes the modal takes a while to appear, so we'll wait longer
    modal_appeared = false
    5.times do |i|
      sleep 2
      if page.has_css?('#primary-modal1.fade.in', visible: true)
        modal_appeared = true
        break
      end
    end

    unless modal_appeared
      # Debug: save state to understand why modal didn't appear
      puts_debug 'Modal did not appear - checking for errors'
      puts_debug "Alert danger: #{find('.alert-danger').text}" if page.has_css?('.alert-danger')
      puts_debug 'Modal exists but not .fade.in' if page.has_css?('#primary-modal1', visible: true)
      save_html_snapshot('/tmp/modal_debug.html')
    end

    expect(modal_appeared).to be(true), 'Modal did not appear after multiple retries'
    finish_page_loading
  end

  context 'with show mode URL (existing behavior)' do
    it 'opens the modal in show mode when clicking embedded_block link' do
      navigate_to_report(@report_show)
      run_report

      # Verify the embedded_block link is present
      expect(page).to have_css('.report-embedded-block-link')

      click_embedded_block_link
      wait_for_modal

      # In show mode, we should see the record displayed (not a form)
      within '#primary-modal1.fade.in' do
        # Should contain the record name (case insensitive as Rails downcases user data)
        expect(page).to have_content(/embedded block test record/i)
        # Should NOT have an active edit form initially (no save button visible)
        expect(page).not_to have_css('form.edit_dynamic_model_test_with_id_rec')
      end
    end
  end

  context 'with edit mode URL ending in /edit (GitHub #325)' do
    it 'opens the modal in edit mode when clicking embedded_block link with /edit URL' do
      navigate_to_report(@report_edit)
      run_report

      # Verify the embedded_block link is present
      expect(page).to have_css('.report-embedded-block-link')

      click_embedded_block_link
      wait_for_modal

      # In edit mode, we should see an editable form
      within '#primary-modal1.fade.in' do
        # Should have an edit form
        expect(page).to have_css('form.edit_dynamic_model_test_with_id_rec', wait: 10)
        # Form should be visible and editable
        expect(page).to have_field('dynamic_model_test_with_id_rec[name]')
        expect(page).to have_button('Save')
      end
    end

    it 'closes the modal when saving in edit mode' do
      navigate_to_report(@report_edit)
      run_report

      click_embedded_block_link
      wait_for_modal

      within '#primary-modal1.fade.in' do
        # Wait for form to load
        expect(page).to have_css('form.edit_dynamic_model_test_with_id_rec', wait: 10)

        # Update a field
        fill_in 'dynamic_model_test_with_id_rec[name]', with: 'Updated Record Name'
        click_button 'Save'
      end

      # Modal should close after save
      expect(page).not_to have_css('#primary-modal1.fade.in', wait: 10)

      # Verify the update was saved (Rails downcases user data)
      @test_record.reload
      expect(@test_record.name).to eq('updated record name')
    end
  end
end
