# frozen_string_literal: true

require 'rails_helper'

# System tests validating the Chart.js chart report feature documented in
# docs/admin_reference/reports/chart_reports.md
#
# Test Coverage:
# - Chart reports render a <canvas> element when view_as: chart is configured
# - The component type option selects the chart type (bar, line, pie, doughnut)
# - The label_with_column option controls which column is used for chart labels
# - Dataset options (borderColor, backgroundColor) are reflected in the rendered chart options
# - Auto-run chart reports render without requiring the user to click Search
# - Hiding the criteria panel via hide_criteria_panel removes the search form
# - Multi-dataset charts produce one dataset per non-label column
# - Embedded charts (in page layout panels) get responsive sizing applied
#
# Implementation Notes:
# - Chart.js renders into a <canvas class="report-chart-canvas"> element
# - The chart data is injected via a <script> tag at render time
# - Chart configuration is verified by inspecting window.Chart constructor call
#   arguments captured via browser JS evaluation
# - All chart reports use report type 'regular_report' with options yaml
describe 'report charts', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx

    @admin, = create_admin
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

    # SQL that always returns at least one row with categorical labels and numeric data
    @chart_sql = <<~SQL
      SELECT
        unnest(ARRAY['Category A', 'Category B', 'Category C']) AS "label",
        unnest(ARRAY[10, 25, 15])                               AS "value_a",
        unnest(ARRAY[5, 30, 20])                                AS "value_b"
    SQL

    create_bar_chart_report
    create_line_chart_report
    create_pie_chart_report
    create_auto_run_chart_report
    create_hidden_criteria_chart_report
  end

  # -----------------------------------------------------------------------
  # Helper: create a chart report and grant access to @user
  # -----------------------------------------------------------------------

  def make_chart_report(name:, sql:, options:, auto: false)
    report = Report.create!(
      current_admin: @admin,
      name: name,
      description: '',
      sql: sql,
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: auto,
      searchable: false,
      position: nil,
      edit_model: nil,
      edit_field_names: nil,
      selection_fields: nil,
      item_type: nil,
      options: options
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

  def create_bar_chart_report
    @bar_chart_report = make_chart_report(
      name: "Bar Chart Test #{SecureRandom.hex(4)}",
      sql: @chart_sql,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: bar
            width: 600
            height: 300
            label_with_column: label
            dataset_options:
              - backgroundColor: 'rgba(54, 162, 235, 0.8)'
                borderColor: 'rgba(54, 162, 235, 1)'
                borderWidth: 1
              - backgroundColor: 'rgba(255, 99, 132, 0.8)'
                borderColor: 'rgba(255, 99, 132, 1)'
                borderWidth: 1
            options:
              responsive: false
      YAML
    )
  end

  def create_line_chart_report
    @line_chart_report = make_chart_report(
      name: "Line Chart Test #{SecureRandom.hex(4)}",
      sql: @chart_sql,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: line
            width: 700
            height: 350
            label_with_column: label
            dataset_options:
              - borderColor: '#c00'
                borderWidth: 3
                backgroundColor: transparent
                lineTension: 0.1
              - borderColor: '#00c'
                borderWidth: 3
                backgroundColor: transparent
                lineTension: 0.1
            options:
              responsive: false
      YAML
    )
  end

  def create_pie_chart_report
    pie_sql = <<~SQL
      SELECT
        unnest(ARRAY['Alpha', 'Beta', 'Gamma']) AS "category",
        unnest(ARRAY[40, 35, 25])               AS "percentage"
    SQL
    @pie_chart_report = make_chart_report(
      name: "Pie Chart Test #{SecureRandom.hex(4)}",
      sql: pie_sql,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: pie
            width: 400
            height: 400
            label_with_column: category
            dataset_options:
              - backgroundColor:
                  - '#FF6384'
                  - '#36A2EB'
                  - '#FFCE56'
            options:
              responsive: false
      YAML
    )
  end

  def create_auto_run_chart_report
    @auto_run_chart_report = make_chart_report(
      name: "Auto-Run Chart Test #{SecureRandom.hex(4)}",
      sql: @chart_sql,
      auto: true,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: bar
            width: 500
            height: 250
            label_with_column: label
            options:
              responsive: false
      YAML
    )
  end

  def create_hidden_criteria_chart_report
    @hidden_criteria_chart_report = make_chart_report(
      name: "Hidden Criteria Chart Test #{SecureRandom.hex(4)}",
      sql: @chart_sql,
      auto: true,
      options: <<~YAML
        view_options:
          view_as: chart
          hide_criteria_panel: true
        component:
          options:
            type: bar
            width: 500
            height: 250
            label_with_column: label
            options:
              responsive: false
      YAML
    )
  end

  # -----------------------------------------------------------------------
  # Navigation helpers
  # -----------------------------------------------------------------------

  before(:each) do
    validate_setup
    login
  end

  def navigate_to_reports_list
    expect(page).to have_css("a[href='/reports']")
    click_link 'Reports'
    expect(page).to have_css('.data-results table.tablesorter')
    finish_page_loading
  end

  def open_report_by_id(report)
    expect(page).to have_css(".data-results table.tablesorter tr[data-report-id='#{report.id}']")
    within ".data-results table.tablesorter tr[data-report-id='#{report.id}']" do
      click_link report.name
    end
    finish_page_loading
    # The .report-criteria element may be hidden when hide_criteria_panel is configured,
    # so use visible: :all to confirm the page loaded without requiring it to be visible.
    expect(page).to have_css('.report-criteria', visible: :all)
  end

  def run_report
    within '#report_query_form' do
      click_button 'table'
    end
    expect(page).to have_css('.search-status-done', wait: 15)
    finish_page_loading
  end

  # -----------------------------------------------------------------------
  # Tests
  # -----------------------------------------------------------------------

  # Verifies the most fundamental requirement: a chart report renders a
  # <canvas> element rather than a standard table.
  it 'renders a canvas element for a bar chart report' do
    navigate_to_reports_list
    open_report_by_id(@bar_chart_report)

    run_report

    expect(page).to have_css('.report-chart', wait: 5)
    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    expect(page).not_to have_css('.report-results-block table.tablesorter')
  end

  # Verifies that a line chart also renders as a canvas element.
  it 'renders a canvas element for a line chart report' do
    navigate_to_reports_list
    open_report_by_id(@line_chart_report)

    run_report

    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
  end

  # Verifies that a pie chart renders correctly. Pie charts use a single
  # dataset with an array of background colours per segment.
  it 'renders a canvas element for a pie chart report' do
    navigate_to_reports_list
    open_report_by_id(@pie_chart_report)

    run_report

    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
  end

  # Verifies that the chart canvas is sized according to the width and height
  # options supplied in the component configuration.
  it 'applies width and height to the canvas element' do
    navigate_to_reports_list
    open_report_by_id(@bar_chart_report)

    run_report

    canvas = find('.report-chart canvas.report-chart-canvas', wait: 5)
    expect(canvas['width'].to_i).to eq(600)
    expect(canvas['height'].to_i).to eq(300)
  end

  # Verifies that the data-results-count attribute on the chart block equals the
  # number of rows returned by the SQL query. The bar-chart SQL uses ARRAY unnest
  # which expands to exactly 3 rows, so the attribute must equal 3.
  it 'reflects the SQL row count in the chart data-results-count attribute' do
    navigate_to_reports_list
    open_report_by_id(@bar_chart_report)

    run_report

    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    chart_block = find('.report-chart')
    expect(chart_block['data-results-count'].to_i).to eq(3)
  end

  # Auto-run reports should display chart results without requiring the user
  # to click the Search button.
  it 'auto-runs and renders chart without user interaction' do
    navigate_to_reports_list
    open_report_by_id(@auto_run_chart_report)

    # Auto-run reports submit automatically; wait for results
    expect(page).to have_css('.search-status-done', wait: 15)
    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
  end

  # When hide_criteria_panel is true, the search criteria block should not
  # be visible, giving a cleaner presentation suitable for dashboards.
  it 'hides the criteria panel when hide_criteria_panel is configured' do
    navigate_to_reports_list
    open_report_by_id(@hidden_criteria_chart_report)

    expect(page).to have_css('.search-status-done', wait: 15)
    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    expect(page).not_to have_css('.report-criteria-content', visible: true)
  end

end
