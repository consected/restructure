# frozen_string_literal: true

# Admin Report Preview Columns Spec - Issue #1000
#
# Tests that the admin report page results preview shows column headers
# that are correctly aligned with the actual data columns returned by the query.
#
# Test 1 (existing): Basic column alignment for a simple report without edit_model.
#   The admin preview form submits an AJAX request through the admin controller.
#   Verifies th count == td count and data-col-type values align positionally.
#
# Test 2 (edit_model cache key bug): When a report has edit_model configured,
#   the table header is cached. The cache key does NOT include the editable? state.
#   When a non-embedded view caches the header WITH an extra <th> for the edit button,
#   and then the admin preview renders the same report (where @embedded_report=true
#   suppresses the edit column), the stale cached header is served with the extra <th>
#   but data rows don't have the extra <td>. This causes all column headers to be
#   shifted by one position. This test verifies header/data column counts match
#   even when edit_model is configured.

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

  context 'with edit_model configured on the report' do
    before(:all) do
      # Create a report WITH edit_model so that editable? returns true in non-embedded contexts
      @editable_report = Report.create!(
        current_admin: @admin,
        name: "Editable Preview Test #{SecureRandom.hex(4)}",
        description: 'Test report for editable column alignment in admin preview',
        sql: 'select * from player_infos limit 10',
        search_attrs: '',
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false,
        position: nil,
        edit_model: 'player_infos',
        edit_field_names: 'first_name,last_name'
      )

      # Clear the cache to remove any stale entries from previous test runs,
      # so we get a clean slate for testing cache behavior.
      Rails.cache.clear
    end

    after(:all) do
      @editable_report&.update(disabled: true, current_admin: @admin) if @editable_report&.persisted?
    end

    it 'shows header column count matching data column count even with edit_model set' do
      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      # Click the edit button for our editable test report
      within "#admin-item-#{@editable_report.id}" do
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
        # The critical assertion: th count must equal td count in the first data row.
        # If the cache key doesn't include editable state, a stale cached header with
        # the edit-button-column <th> will be served but data rows won't have the
        # matching <td>, causing a count mismatch.
        all_header_cells = all('thead tr th')
        first_row_cells = all('tbody tr:first-child td')

        expect(all_header_cells.length).to eq(first_row_cells.length),
          "Header row has #{all_header_cells.length} columns but data row has #{first_row_cells.length} — " \
          'column misalignment detected (likely stale cached header with edit-button-column <th>)'

        # The admin preview should NOT have an edit-button-column header since @embedded_report is set
        edit_button_headers = all('thead th.edit-button-column', minimum: 0)
        expect(edit_button_headers.length).to eq(0),
          'Admin preview should not show edit-button-column header when @embedded_report is set'

        # Verify positional alignment of data column headers with data cells
        data_header_cells = all('thead th.table-header')
        data_cells = all('tbody tr:first-child td.report-el')
        expect(data_header_cells.length).to eq(data_cells.length),
          "Data header count (#{data_header_cells.length}) != data cell count (#{data_cells.length})"

        data_header_cells.each_with_index do |th, i|
          th_col = th[:'data-col-type']
          td_col = data_cells[i][:'data-col-type']
          expect(th_col).to eq(td_col),
            "Header at position #{i} has data-col-type '#{th_col}' " \
            "but data cell has '#{td_col}' — columns are shifted"
        end
      end
    end

    it 'shows a visual indicator on the Edit table data button when fields are configured' do
      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      # Click the edit button for our editable test report (which has edit_model set)
      within "#admin-item-#{@editable_report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      # Wait for the edit form to load
      expect(page).to have_css('#report_query_form', wait: 10)

      # The "Edit table data?" button should have a visual indicator (btn-info class and check icon)
      edit_table_btn = find('a[href="#edit_table_block"]')
      expect(edit_table_btn[:class]).to include('btn-info'),
        'Edit table data button should have btn-info class when edit table fields are configured'
      expect(edit_table_btn).to have_css('.glyphicon-ok'),
        'Edit table data button should show a check icon when edit table fields are configured'
    end
  end
end
