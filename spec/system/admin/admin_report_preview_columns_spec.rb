# frozen_string_literal: true

# Admin Report Preview Columns Spec - Issue #1000
#
# Tests that the admin report page results preview shows column headers
# that are correctly aligned with the actual data columns returned by the query.
#
# The bug: the admin preview form submits an AJAX request to the user-facing
# ReportsController, which requires user authentication via UserBaseController's
# `before_action :authenticate_user!`. When an admin is signed in only as admin
# (no user session), the AJAX request fails and column headers are not shown
# correctly. The fix routes the preview through the admin controller instead.

require 'rails_helper'

describe 'admin report preview columns - Issue #1000', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    # Get the actual column names from the player_infos table as they would
    # appear in a `select *` query result
    @expected_columns = ActiveRecord::Base.connection.columns('player_infos').map(&:name)

    # Ensure there is data in player_infos for the preview to return results
    unless PlayerInfo.exists?
      create_user
      create_master
      PlayerInfo.create!(
        master: @master,
        first_name: 'test',
        last_name: 'user',
        current_user: @user
      )
    end

    # Create a simple report for testing column alignment
    @report = Report.create!(
      current_admin: @admin,
      name: "Preview Columns Test #{SecureRandom.hex(4)}",
      description: 'Test report for column alignment in admin preview',
      sql: 'select * from player_infos limit 10',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      position: nil
    )
  end

  after(:all) do
    @report&.update(disabled: true, current_admin: @admin) if @report&.persisted?
  end

  it 'shows column headers matching the actual query columns in the correct order' do
    admin_sign_in_with_2fa

    visit '/admin/reports'
    finish_page_loading

    # Click the edit button for our test report
    within "#admin-item-#{@report.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('#report_query_form', wait: 10)

    # Click the "run" button to execute the preview
    within '#report_query_form' do
      click_button 'run'
    end

    # Wait for the AJAX response to load results into #embed_results_block
    expect(page).to have_css('#embed_results_block table.report-table', wait: 15)
    finish_page_loading

    within '#embed_results_block table.report-table' do
      # Check ALL th elements (including any edit-button columns) align with ALL td elements.
      all_header_cells = all('thead tr th')
      first_row_cells = all('tbody tr:first-child td')

      expect(all_header_cells.length).to eq(first_row_cells.length),
        "Header row has #{all_header_cells.length} columns but data row has #{first_row_cells.length} — " \
        'columns are visually misaligned'

      # Collect just the data column headers (with data-col-type attribute)
      data_header_cells = all('thead th.table-header')
      header_col_types = data_header_cells.map { |th| th[:'data-col-type'] }

      # Verify we got headers for all expected columns
      expect(data_header_cells.length).to eq(@expected_columns.length),
        "Expected #{@expected_columns.length} column headers but found #{data_header_cells.length}"

      # Verify each header's data-col-type matches the expected column name in order
      @expected_columns.each_with_index do |expected_col, i|
        expect(header_col_types[i]).to eq(expected_col),
          "Header at position #{i} has data-col-type '#{header_col_types[i]}' " \
          "but expected '#{expected_col}'. " \
          "Full header order: #{header_col_types.inspect}"
      end

      # Verify the first data row's td data-col-type values align positionally with headers
      data_cells = all('tbody tr:first-child td.report-el')
      expect(data_cells.length).to eq(@expected_columns.length),
        "Expected #{@expected_columns.length} data cells but found #{data_cells.length}"

      data_cells.each_with_index do |td, i|
        td_col_type = td[:'data-col-type']
        expect(td_col_type).to eq(header_col_types[i]),
          "Data cell at position #{i} has data-col-type '#{td_col_type}' " \
          "but header has '#{header_col_types[i]}'"
      end
    end
  end
end
