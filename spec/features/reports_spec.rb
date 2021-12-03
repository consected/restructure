# frozen_string_literal: true

require 'rails_helper'

describe 'reports', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include ItemFlagSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    SetupHelper.feature_setup

    @admin, = create_admin

    seed_database
    create_data_set_outside_tx

    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :view_reports, current_admin: @admin, user: @user
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :export_csv, current_admin: @admin, user: @user

    expect(@user.can?(:view_reports)).to be_truthy
    expect(@user.can?(:export_csv)).to be_truthy

    Admin::UserAccessControl.create! user: @user, app_type: @user.app_type, access: :read, resource_type: :report, resource_name: :_all_reports_, current_admin: @admin
    expect(@user.has_access_to?(:read, :report, :_all_reports_)).to be_truthy

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

    @report = r
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

  before :each do
    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id

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
end
