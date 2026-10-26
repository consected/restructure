# frozen_string_literal: true

# Verifies the admin report preview displays retrieved record counts and honors
# the report's hide_result_count option.

require 'rails_helper'

describe 'admin report preview count - Issue #1497', js: true, driver: $browser_driver do
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    @reports = [
      create_preview_report('singular', 'select 1 as preview_value'),
      create_preview_report('zero', 'select 1 as preview_value where false'),
      create_preview_report('plural', 'select 1 as preview_value union all select 2 as preview_value'),
      create_preview_report(
        'hidden count',
        'select 1 as preview_value union all select 2 as preview_value',
        options: "view_options:\n  hide_result_count: true"
      )
    ]
  end

  after(:all) do
    @reports&.each do |report|
      report.update(disabled: true, current_admin: @admin) if report.persisted?
    end
  end

  it 'shows singular and plural counts for the returned records' do
    admin_sign_in_with_2fa

    run_report_preview(@reports[0])
    expect_preview_count_text('1 record')

    run_report_preview(@reports[2])
    expect_preview_count_text('2 records')
  end

  it 'shows a zero count when no records are returned' do
    admin_sign_in_with_2fa

    run_report_preview(@reports[1])
    expect_preview_count_text('0 records')
  end

  it 'does not show a count when hide_result_count is enabled' do
    admin_sign_in_with_2fa

    run_report_preview(@reports[3])

    within '#report_query_form .report-criteria__actions' do
      expect(page).not_to have_css('.search_count_reports')
    end
  end

  def expect_preview_count_text(text)
    within '#report_query_form .report-criteria__actions' do
      expect(page).to have_css('.search-results-count', exact_text: text, wait: 10)
    end
  end

  def create_preview_report(name, sql, options: nil)
    Report.create!(
      current_admin: @admin,
      name: "Preview Count #{name} #{SecureRandom.hex(4)}",
      description: 'Test report for record counts in the admin preview',
      sql:,
      options:,
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      position: nil
    )
  end

  def run_report_preview(report)
    visit '/admin/reports'
    finish_page_loading

    within "#admin-item-#{report.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('#report_query_form', wait: 10)
    within '#report_query_form' do
      click_button 'run'
    end

    expect(page).to have_css('#embed_results_block table.report-table', wait: 15)
    finish_page_loading
  end
end
