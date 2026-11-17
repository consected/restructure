# frozen_string_literal: true

module ReportSupport
  def create_reports
    @report_sql = sql = "select * from item_flags if1\r\ninner join item_flag_names ifn\r\non if1.item_flag_name_id = ifn.id"

    @report1 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: true,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-1')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report1.alt_resource_name, current_admin: @admin

    @report2 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: true,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-1')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report2.alt_resource_name, current_admin: @admin

    @report3 = Report.create(current_admin: @admin, name: "New Report #{SecureRandom.hex}", description: '', sql: sql,
                             search_attrs: '', disabled: false, report_type: 'regular_report', auto: false, searchable: false,
                             position: nil, edit_model: nil, edit_field_names: nil, selection_fields: nil, item_type: 'type-2')
    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report,
                                     resource_name: @report3.alt_resource_name, current_admin: @admin
  end

  def check_reports_accessible
    rn = @report1.alt_resource_name

    expect(@user.can?(:view_reports)).to be_truthy
    expect(@user.has_access_to?(:read, :report, rn)).to be_truthy

    expect(User.find_by_sql([@report_sql]).length).to be > 0
  end

  #
  # @params report [Report|Integer] the report to open
  def open_report_by_id(report)
    report = Report.find(report) if report.is_a? Integer

    finish_page_loading
    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{report.id}']")
    within ".data-results table.tablesorter tr[data-report-id='#{report.id}']" do
      click_link report.name
    end
    finish_page_loading
    # The .report-criteria element may be hidden when hide_criteria_panel is configured,
    # so use visible: :all to confirm the page loaded without requiring it to be visible.
    expect(page).to have_css('.report-criteria', visible: :all)
  end

  def run_report_table
    within('#report_query_form') { click_button 'table' }
    finish_page_loading
    expect(page).to have_css('.report-results-block table')
  end

  def open_report_result_link(label, column: nil)
    wait_for_ui_to_settle
    result = find('.report-results-block')
    result = result.find("td[data-col-type='#{column}']") if column
    link = result.find_link(label, exact: true)
    scroll_into_view(link)
    wait_for_ui_to_settle
    link.click
    finish_page_loading
    finish_form_formatting
    find('#primary-modal.in', wait: 10)
  end

  def expect_report_modal_masters(master, excluded_master)
    modal = find('#primary-modal.in', wait: 10)
    expect(modal).to have_css(".master-result#master-#{master.id}", wait: 10)
    expect(modal).to have_no_css(".master-result#master-#{excluded_master.id}")
  end
end
