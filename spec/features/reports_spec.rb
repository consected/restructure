require 'rails_helper'

describe "reports", js: true, driver: :app_firefox_driver do

  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    @admin, _ = create_admin

    seed_database

    create_data_set

    @user, @good_password  = create_user
    @good_email  = @user.email

    UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :view_reports, current_admin: @admin, user: @user
    UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :export_csv, current_admin: @admin, user: @user

    expect(@user.can?(:view_reports)).to be_truthy

    UserAccessControl.create! user: @user, app_type: @user.app_type, access: :read, resource_type: :report, resource_name: :_all_reports_, current_admin: @admin
    expect(@user.has_access_to?(:read, :report, :_all_reports_)).to be_truthy

    rl = Report.where(name: "Item Flags types")
    unless rl.count > 0
      r = Report.create(current_admin: @admin, name: "Item Flags types", description: "", sql: "select * from item_flags if1\r\ninner join item_flag_names ifn\r\non if1.item_flag_name_id = ifn.id", search_attrs: "",  disabled: false, report_type: "regular_report", auto: false, searchable: false, position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: nil)
      r.save!
      expect(r.can_access? @user).to be_truthy
    else
      r = rl.first
    end
    @report = r
  end

  before :each do
    user = User.where(email: @good_email).first

    expect(user).to be_a User
    expect(user.id).to equal @user.id

    #login_as @user, scope: :user

    login

  end


  def get_list
    expect(page).to have_css("a[href='/reports']")
    click_link "Reports"
    expect(page).to have_css('.data-results table.tablesorter tr[data-report-id]')
  end

  def open_report id
    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{id}']")
    within ".data-results table.tablesorter tr[data-report-id='#{id}']" do
      click_link "Item Flags types"
    end
  end

  def get_column_values col, table, db_table=nil

    db_table = "[data-col-table='#{db_table}']" if db_table

    resels = table.all("tr td[data-col-type='#{col}']#{db_table}")

    resels.map {|e| e.text}
  end

  it "allows user to view a list of available reports" do

    get_list
  end

  it "runs a report" do
    get_list
    open_report @report.id
    expect(page).to have_css(".report-criteria")

    within "#report_query_form" do
      click_button 'table'
    end

    expect(page).to have_css('.search-status-done')
    expect(page).to have_css('#report-results-block table.tablesorter')
    results = all('#report-results-block table.tablesorter tr')
    expect(results.length).to be > 1

    within '#report-results-block' do
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
      vals.map! {|e| e.to_i}
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

  it "exports a report" do
    get_list
    open_report @report.id
    expect(page).to have_css(".report-criteria")

    within "#report_query_form" do
      click_button 'csv'
      sleep 2
    end

    expect(page).not_to have_css('.alert')

  end
end
