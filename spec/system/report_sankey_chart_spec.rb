# frozen_string_literal: true

require 'rails_helper'

# System tests validating the Sankey diagram chart report feature using
# the chartjs-chart-sankey plugin, as documented in
# docs/admin_reference/reports/chart_reports.md
#
# Test Coverage:
# - Sankey chart reports render a <canvas> element when type: sankey is configured
# - The canvas has the correct width and height from component options
# - The data-results-count attribute reflects the SQL row count
# - Sankey charts use a different data format: SQL must return from/to/flow columns
#   rather than the label + value columns used by standard chart types
# - The chartjs-chart-sankey plugin (SankeyController) must be loaded and registered
#   so that Chart.js recognises the 'sankey' type
# - Auto-run Sankey charts render without user interaction
#
# Implementation Notes:
# - Sankey data format: each SQL row produces {from, to, flow} objects in a single dataset
# - The columns 'from', 'to', and 'flow' are the defaults; they can be overridden via
#   the sankey_columns option: { from_column: 'source', to_column: 'dest', flow_column: 'value' }
# - The chart ERB template detects type: sankey and builds data differently from standard charts
# - chartjs-chart-sankey must be required after chart.js in the asset pipeline and
#   its SankeyController registered with Chart.register()
describe 'sankey chart reports', js: true, driver: $browser_driver do
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

    # SQL returning from/to/flow columns for a Sankey diagram
    # Represents a simple flow: A->B (10), A->C (5), B->C (10), D->C (7)
    @sankey_sql = <<~SQL
      SELECT
        unnest(ARRAY['A', 'A', 'B', 'D']) AS "from",
        unnest(ARRAY['B', 'C', 'C', 'C']) AS "to",
        unnest(ARRAY[10, 5, 10, 7])       AS "flow"
    SQL

    # SQL using custom column names (source/destination/value) for override testing
    @sankey_custom_cols_sql = <<~SQL
      SELECT
        unnest(ARRAY['Step1', 'Step1', 'Step2']) AS "source",
        unnest(ARRAY['Step2', 'Step3', 'Step3']) AS "destination",
        unnest(ARRAY[20, 10, 15])                AS "value"
    SQL

    create_sankey_chart_report
    create_sankey_custom_columns_report
    create_auto_run_sankey_report
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

  def create_sankey_chart_report
    @sankey_chart_report = make_chart_report(
      name: "Sankey Chart Test #{SecureRandom.hex(4)}",
      sql: @sankey_sql,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: sankey
            width: 700
            height: 400
            dataset_options:
              - label: Flow diagram
                colorMode: gradient
                alpha: 0.6
            options:
              responsive: false
      YAML
    )
  end

  def create_sankey_custom_columns_report
    @sankey_custom_columns_report = make_chart_report(
      name: "Sankey Custom Cols Test #{SecureRandom.hex(4)}",
      sql: @sankey_custom_cols_sql,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: sankey
            width: 600
            height: 300
            sankey_columns:
              from_column: source
              to_column: destination
              flow_column: value
            options:
              responsive: false
      YAML
    )
  end

  def create_auto_run_sankey_report
    @auto_run_sankey_report = make_chart_report(
      name: "Auto-Run Sankey Test #{SecureRandom.hex(4)}",
      sql: @sankey_sql,
      auto: true,
      options: <<~YAML
        view_options:
          view_as: chart
        component:
          options:
            type: sankey
            width: 600
            height: 350
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

  # Verifies that a Sankey chart report renders a <canvas> element instead of
  # a table, confirming that the chartjs-chart-sankey plugin is loaded and the
  # ERB template handles the 'sankey' type correctly.
  it 'renders a canvas element for a sankey chart report' do
    navigate_to_reports_list
    open_report_by_id(@sankey_chart_report)

    run_report

    expect(page).to have_css('.report-chart', wait: 5)
    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    expect(page).not_to have_css('.report-results-block table.tablesorter')
  end

  # Verifies that the canvas is sized according to the width and height configured
  # in the component options.
  it 'applies width and height to the sankey canvas element' do
    navigate_to_reports_list
    open_report_by_id(@sankey_chart_report)

    run_report

    canvas = find('.report-chart canvas.report-chart-canvas', wait: 5)
    expect(canvas['width'].to_i).to eq(700)
    expect(canvas['height'].to_i).to eq(400)
  end

  # Verifies that data-results-count reflects the number of rows from the SQL query.
  # The sankey SQL uses ARRAY unnest which expands to exactly 4 rows.
  it 'reflects the SQL row count in the data-results-count attribute' do
    navigate_to_reports_list
    open_report_by_id(@sankey_chart_report)

    run_report

    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    chart_block = find('.report-chart')
    expect(chart_block['data-results-count'].to_i).to eq(4)
  end

  # Verifies that custom column name mapping (sankey_columns option) works:
  # when from_column/to_column/flow_column are specified, those SQL columns
  # are used instead of the defaults (from/to/flow).
  it 'renders a sankey chart with custom column names' do
    navigate_to_reports_list
    open_report_by_id(@sankey_custom_columns_report)

    run_report

    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
    chart_block = find('.report-chart')
    expect(chart_block['data-results-count'].to_i).to eq(3)
  end

  # Verifies that auto-run Sankey reports render without requiring the user
  # to click Search.
  it 'auto-runs and renders sankey chart without user interaction' do
    navigate_to_reports_list
    open_report_by_id(@auto_run_sankey_report)

    expect(page).to have_css('.search-status-done', wait: 15)
    expect(page).to have_css('.report-chart canvas.report-chart-canvas', wait: 5)
  end
end
