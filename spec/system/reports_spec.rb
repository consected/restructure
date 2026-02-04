# frozen_string_literal: true

require 'rails_helper'

# System tests for reports functionality
#
# Test Coverage:
# - Report listing and search with various criteria
# - Report criteria fields (date ranges, dropdowns, filter_selector)
# - Report results display and pagination
# - Report parameter substitution and filtering
# - filter_selector JavaScript callback: Tests that changing a parent
#   dropdown (protocol) updates dependent dropdowns (sub_process) via
#   the select_filtering_changed callback without JavaScript errors
#
# Implementation Notes:
# - Report criteria dropdowns use chosen.js for enhanced selection
# - Use select_from_dropdown_field with is_report: true for report fields
# - The filter_selector mechanism updates data-big-select-subtype attributes
#   on dependent fields when a parent selection changes
describe 'reports', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include ItemFlagSupport
  include FeatureSupport
  include TestFieldsDmSupport
  include ReportSupport

  before(:all) do
    SetupHelper.feature_setup

    @admin, = create_admin

    seed_database
    create_data_set_outside_tx
    setup_report_user
    setup_fields_dm

    rl = Report.where(name: 'Item Flags types')

    sql = "select * from item_flags if1\r\ninner join item_flag_names ifn\r\non if1.item_flag_name_id = ifn.id"
    if rl.count > 0
      r = rl.first
    else
      r = Report.create(current_admin: @admin, name: 'Item Flags types', description: '', sql: sql, search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: false, position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
      r.save!
      expect(r.can_access?(@user)).to be_truthy
    end

    5.times { create_item }
    expect(Report.connection.execute(sql).first).not_to be nil

    Report.active.where('id != :id', id: r.id).update_all(disabled: true, admin_id: @admin.id)

    create_report_with_all_criteria_fields
    create_report_with_add_item_button
    create_report_with_activity_log_add_item_button
    create_report_with_external_identifier_add_item_button
    create_report_with_filter_selector

    @report = r
  end

  def setup_report_user
    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :view_reports, current_admin: @admin, user: @user
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :export_csv, current_admin: @admin, user: @user

    expect(@user.can?(:view_reports)).to be_truthy
    expect(@user.can?(:export_csv)).to be_truthy

    Admin::UserAccessControl.create! user: @user, app_type: @user.app_type, access: :read, resource_type: :report, resource_name: :_all_reports_, current_admin: @admin
    expect(@user.has_access_to?(:read, :report, :_all_reports_)).to be_truthy
  end

  def create_report_with_all_criteria_fields
    sql = 'select * from masters limit 1;'
    search_attrs = <<~END_CONFIG


      number_field:
        number:
          all: true
          multiple: single
          disabled: false

      numbers_field:
        number:
          all: true
          multiple: multiple
          disabled: false

      text_field:
        text:
          all: true
          multiple: single
          disabled: false

      texts_field:
        text:
          all: true
          multiple: multiple
          disabled: false

      date_field:
        date:
          all: true
          multiple: single
          disabled: false

      dates_field:
        date:
          all: true
          multiple: multiple
          disabled: false

      state_field:
        address_state:
          all: true
          multiple: single
          disabled: false

      states_field:
        address_state:
          all: true
          multiple: multiple
          disabled: false

      accuracy_field:
        accuracy_score:
          all: true
          multiple: single
          disabled: false

      accuracys_field:
        accuracy_score:
          all: true
          multiple: multiple
          disabled: false

      gs_field:
        general_selection:
          all: true
          multiple: single
          disabled: false

      gss_field:
        general_selection:
          all: true
          multiple: multiple
          disabled: false

      config_field:
        config_selector:
          all: true
          multiple: single
          disabled: false
          selections:
            a: a
            b: b

      configs_field:
        config_selector:
          all: true
          multiple: multiple
          disabled: false
          selections:
            a: a
            b: b

      protocol_field:
        protocol:
          all: true
          multiple: single
          disabled: false

      protocols_field:
        protocol:
          all: true
          multiple: multiple
          disabled: false

      ts_field:
        sub_process:
          all: true
          multiple: single
          disabled: false

      tss_field:
        sub_process:
          all: true
          multiple: multiple
          disabled: false

      tm_field:
        protocol_event:
          all: true
          multiple: single
          disabled: false

      tms_field:
        protocol_event:
          all: true
          multiple: multiple
          disabled: false

      flag_field:
        item_flag_name:
          all: true
          multiple: single
          disabled: false

      flags_field:
        item_flag_name:
          all: true
          multiple: multiple
          disabled: false

      username_field:
        user:
          all: true
          multiple: single
          disabled: false

      usernames_field:
        user:
          all: true
          multiple: multiple
          disabled: false

    END_CONFIG

    @criteria_field_report = Report.create(current_admin: @admin,
                                           name: 'Criteria Fields', description: '', sql: sql, search_attrs: search_attrs,
                                           disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                                           position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
  end

  # Creates a report with add_item_button substitution for a dynamic model.
  # The button uses the temporary master (-1) to create new records.
  # Tests: {{add_item_button_to_temporary_master_dynamic_model__test_with_id_recs}}
  def create_report_with_add_item_button
    dm = DynamicModel.active.find_by(table_name: 'test_with_id_recs')
    expect(dm).not_to be nil

    sql = 'select * from test_with_id_recs order by id desc limit 1;'
    search_attrs = <<~END_CONFIG
      number_field:
        number:
          all: true
          multiple: single
          disabled: false
    END_CONFIG

    description = <<~END_DESC
      This report has an add item button.

      {{add_item_button_to_temporary_master_dynamic_model__test_with_id_recs}}
    END_DESC

    @add_item_button_report = Report.create(current_admin: @admin,
                                            name: 'Add Item Button', description:, sql: sql, search_attrs: search_attrs,
                                            disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                                            position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
  end

  # Creates a report with add_item_button substitution for an activity log.
  # Activity logs require the activity suffix (e.g., __primary) in the resource name.
  # Tests: {{add_item_button_to_temporary_master_activity_log__player_contact_phone__primary}}
  def create_report_with_activity_log_add_item_button
    expect(Master.find(-1)).to be_a Master

    sql = 'select * from masters limit 1;'
    search_attrs = <<~END_CONFIG
      number_field:
        number:
          all: true
          multiple: single
          disabled: false
    END_CONFIG

    description = <<~END_DESC
      This report has an activity log add item button.

      {{add_item_button_to_temporary_master_activity_log__player_contact_phone__primary}}
    END_DESC

    @activity_log_add_item_button_report = Report.create(current_admin: @admin,
                                                         name: 'Activity Log Add Item Button', description:, sql: sql, search_attrs: search_attrs,
                                                         disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                                                         position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
  end

  # Creates a report with add_item_button substitution for an external identifier.
  # External identifiers use the simple resource name (e.g., scantrons).
  # Tests: {{add_item_button_to_temporary_master_scantrons}}
  def create_report_with_external_identifier_add_item_button
    expect(Master.find(-1)).to be_a Master
    ei = ExternalIdentifier.active.find_by(name: 'scantrons')
    expect(ei).not_to be_nil

    sql = 'select * from masters limit 1;'
    search_attrs = <<~END_CONFIG
      number_field:
        number:
          all: true
          multiple: single
          disabled: false
    END_CONFIG

    description = <<~END_DESC
      This report has an external identifier add item button.

      {{add_item_button_to_temporary_master_scantrons}}
    END_DESC

    @external_identifier_add_item_button_report = Report.create(current_admin: @admin,
                                                                name: 'External Identifier Add Item Button', description:, sql: sql, search_attrs: search_attrs,
                                                                disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                                                                position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
  end

  # Creates a report with filter_selector configuration to test the JavaScript
  # filtering functionality in report_criteria.js. The protocol field filters
  # the sub_process field's optgroups when changed.
  def create_report_with_filter_selector
    sql = 'select * from masters limit 1;'
    search_attrs = <<~END_CONFIG
      protocol_filter:
        protocol:
          all: true
          multiple: single
          disabled: false
          filter_selector: sub_process_filter

      sub_process_filter:
        sub_process:
          all: true
          multiple: single
          disabled: false
    END_CONFIG

    @filter_selector_report = Report.create(current_admin: @admin,
                                            name: 'Filter Selector Test',
                                            description: 'Tests filter_selector functionality',
                                            sql: sql,
                                            search_attrs: search_attrs,
                                            disabled: false,
                                            report_type: 'regular_report',
                                            auto: false,
                                            searchable: false,
                                            position: nil,
                                            edit_model: nil,
                                            edit_field_names: nil,
                                            selection_fields: nil,
                                            item_type: nil)
  end

  before :each do
    setup_report_user
    validate_setup

    login
  end

  def get_list
    expect(@user.can?(:view_reports)).to be_truthy
    expect(page).to have_css("a[href='/reports']")
    click_link 'Reports'
    expect(page).to have_css('.data-results table.tablesorter tr[data-report-id]')
  end

  def open_report(id, name = nil)
    name ||= 'Item Flags types'
    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{id}']")
    within ".data-results table.tablesorter tr[data-report-id='#{id}']" do
      click_link name
    end
    has_css? '.status-compiled'
  end

  def get_column_values(col, table, db_table = nil)
    db_table = "[data-col-table='#{db_table}']" if db_table

    resels = table.all("tr td[data-col-type='#{col}']#{db_table}")

    resels.map(&:text)
  end

  it 'allows user to view a list of available reports' do
    get_list
    logout
  end

  it 'runs a report' do
    get_list
    open_report @report.id
    expect(page).to have_css('.report-criteria')

    within '#report_query_form' do
      click_button 'table'
    end

    expect(page).to have_css('.search-status-done')
    expect(page).to have_css('.report-results-block')
    expect(page).to have_css('.report-results-block table')
    expect(page).to have_css('.report-results-block table.tablesorter')
    results = all('.report-results-block table.tablesorter tr')
    expect(results.length).to be > 1

    within '.report-results-block' do
      table = find('table.tablesorter')
      # sort the item_flag_name_id column
      ifn_id = all('th.tablesorter-header')[0]

      ifn_id.click
      sleep 0.5
      expect(ifn_id['class']).to include 'tablesorter-headerAsc'

      table = find('table.tablesorter')
      # vals = get_column_values 'id', table, 'item_flags'
      # vals.map! {|e| e.to_i}
      # expect(vals).to eq vals.sort

      ifn_id.click
      sleep 0.5
      expect(ifn_id['class']).to include 'tablesorter-headerDesc'

      vals = get_column_values 'id', table, 'item_flags'
      vals.map!(&:to_i)
      expect(vals).to eq vals.sort.reverse

      sleep 0.5
      # sort the item_type column
      itc = all('th.tablesorter-header')[9]

      itc.click
      sleep 0.5

      expect(itc['class']).to include 'tablesorter-headerAsc'

      vals = get_column_values 'item_type', table, 'item_flag_names'
      expect(vals).to eq vals.sort

      itc.click
      sleep 0.5
      expect(itc['class']).to include 'tablesorter-headerDesc'

      vals = get_column_values 'item_type', table, 'item_flag_names'
      expect(vals).to eq vals.sort.reverse
    end
  end

  it 'exports a report' do
    get_list
    open_report @report.id
    expect(page).to have_css('.report-criteria')

    expect(@user.can?(:export_csv)).to be_truthy
    expect(page).not_to have_css('.alert')
    within '#report_query_form' do
      sleep 2
      click_button 'csv'
      sleep 2
    end

    expect(page).not_to have_css('.alert')
  end

  it 'has many criteria field types' do
    get_list
    open_report @criteria_field_report.id, 'Criteria Fields'
    expect(page).to have_css('.report-criteria')

    within '#report_query_form' do
      click_button 'table'
    end
  end

  # Tests add_item_button substitution for dynamic models.
  # Dynamic models need the 'dynamic-model--' prefix in the data-target attribute.
  it 'shows add item button on report with criteria' do
    setup_access :dynamic_model__test_with_id_recs, user: @user

    get_list

    open_report @add_item_button_report.id, 'Add Item Button'
    expect(page).to have_css('.report-criteria')
    expect(page).to have_css('a.add-item-button')
    aib = find('a.add-item-button')
    puts "Add Item Button href: #{aib[:href]}"

    aib.click

    expect(page).to have_css('#primary-modal1.fade.in')
    expect(page).to have_css('#primary-modal1.fade.in h4.list-group-item-heading', text: 'Test Records With ID')

    debug_process_status
    within('form.new_dynamic_model_test_with_id_rec') do
      fill_in_field 'value', 'New Test Value'
      fill_in_field 'name', 'New Test Name'
      click_button 'Save'
    end

    finish_form_formatting

    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.report-results-block table')
    expect(page).to have_css('.report-results-block table', text: /new test value/)
    expect(page).to have_css('.report-results-block table', text: /new test name/)
  end

  # Tests add_item_button substitution for activity logs.
  # Activity logs use the hyphenated_name with activity suffix (e.g., activity-log--player-contact-phone-primary).
  it 'shows activity log add item button on report' do
    # Access control uses the base table resource name
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user

    let_user_create_master(@user)
    create_master(@user)

    get_list

    open_report @activity_log_add_item_button_report.id, 'Activity Log Add Item Button'
    expect(page).to have_css('.report-criteria')
    expect(page).to have_css('a.add-item-button')
    aib = find('a.add-item-button')

    # Verify the button has correct attributes for activity logs with activity suffix
    puts "Activity Log Add Item Button href: #{aib[:href]}"
    puts "Activity Log Add Item Button data-target: #{aib[:'data-target']}"

    aib.click

    expect(page).to have_css('#primary-modal1.fade.in')

    debug_process_status
    within('form.new_activity_log_player_contact_phone') do
      fill_in_field 'data', 'Test activity log data'
      click_button 'Save'
    end

    finish_form_formatting

    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.report-results-block')
  end

  # Tests add_item_button substitution for external identifiers.
  # External identifiers use simple hyphenated_name (e.g., scantron for scantrons table).
  it 'shows external identifier add item button on report' do
    setup_access :scantrons, user: @user

    let_user_create_master(@user)
    create_master(@user)

    get_list

    open_report @external_identifier_add_item_button_report.id, 'External Identifier Add Item Button'
    expect(page).to have_css('.report-criteria')
    expect(page).to have_css('a.add-item-button')
    aib = find('a.add-item-button')

    # Verify the button has correct attributes for external identifiers
    puts "External Identifier Add Item Button href: #{aib[:href]}"
    puts "External Identifier Add Item Button data-target: #{aib[:'data-target']}"

    aib.click

    expect(page).to have_css('#primary-modal1.fade.in')

    debug_process_status
    within('form.new_scantron') do
      # External identifier forms typically have an ID field to fill in
      fill_in_field 'scantron_id', '123456789'
      click_button 'Save'
    end

    finish_form_formatting

    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.report-results-block')
  end

  # Test that filter_selector configuration in report criteria correctly filters
  # optgroups in dependent dropdowns. This verifies backward compatibility of
  # the select_filtering_changed JavaScript function when called from report_criteria.js.
  it 'filters dependent dropdown when parent selection changes via filter_selector' do
    protocol = Classification::Protocol.active.first
    expect(protocol).not_to be_nil, 'No active protocol found for filtering test'

    get_list
    open_report @filter_selector_report.id, 'Filter Selector Test'
    finish_page_loading
    expect(page).to have_css('.report-criteria')

    # Verify the filter_selector attribute is set on the protocol field
    protocol_select = find('select[name="search_attrs[protocol_filter]"]', visible: :all)
    expect(protocol_select['data-filter-selector']).to eq('sub_process_filter')

    # Verify sub_process subtype is initially empty
    sub_process_select = find('select[name="search_attrs[sub_process_filter]"]', visible: :all)
    expect(sub_process_select['data-big-select-subtype']).to eq(''), 'Initial subtype should be empty'

    # Use helper to select from the dropdown (detects chosen.js automatically for reports)
    select_from_dropdown_field('protocol_filter', protocol.name, is_report: true)
    sleep 0.5 # Allow JavaScript filtering to process

    # After selecting a protocol, the sub_process select should have its
    # data-big-select-subtype attribute updated to the protocol's ID
    # (This verifies select_filtering_changed was called without errors)
    sub_process_select = find('select[name="search_attrs[sub_process_filter]"]', visible: :all)
    updated_subtype = sub_process_select['data-big-select-subtype']
    expect(updated_subtype).to eq(protocol.id.to_s),
                               "Expected sub_process subtype to be '#{protocol.id}', got '#{updated_subtype}'"
  end
end
