# frozen_string_literal: true

# Covers result-cell links opening filtered modal reports and master lists,
# including full search attribute names with underscores and ordinary URL columns.
require 'rails_helper'

describe 'report result modal links', js: true do
  include ModelSupport
  include MasterSupport
  include FeatureSupport
  include ReportSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    SetupHelper.feature_setup
    seed_database
    @admin, = create_admin
    @user, @good_password = create_user
    setup_access :view_reports, resource_type: :general, access: :read
    setup_access :_all_reports_, resource_type: :report, access: :read
    let_user_create_master
    @matching_master = create_master
    @excluded_master = create_master
    @modal_reports = []

    hidden_buttons = <<~YAML
      view_options:
        hide_search_button: true
        hide_master_results_list_search_button: true
        hide_export_buttons: true
    YAML
    @simple_target = create_modal_target('player', options: hidden_buttons)
    @underscore_target = create_modal_target('player_record_id', options: hidden_buttons)
    @table_target = create_modal_target('player_record_id')
    @search_target = create_modal_target('player_record_id', report_type: 'search')
    @source_report = create_modal_report(
      name: 'Modal link source',
      sql: <<~SQL.squish,
        SELECT
          #{@matching_master.id} AS search_reports_#{@simple_target.id}_player,
          #{@matching_master.id} AS search_reports_#{@underscore_target.id}_player_record_id,
          '[View table](/reports/#{@table_target.id}' || chr(63) ||
            'search_attrs[player_record_id]=#{@matching_master.id}&search_attrs[no_run]=true#open-embedded-report)' AS table_link,
          '[View masters](/reports/#{@search_target.id}' || chr(63) ||
            'search_attrs[player_record_id]=#{@matching_master.id}&search_attrs[no_run]=true&force_run=true#open-embedded-report)' AS masters_link
      SQL
      options: <<~YAML
        column_options:
          show_as:
            table_link: url
            masters_link: url
      YAML
    )
  end

  after(:all) do
    @modal_reports&.each { |report| report.update!(disabled: true, current_admin: @admin) }
  end

  before(:each) do
    login
    visit '/reports'
    finish_page_loading
    open_report_by_id(@source_report)
    run_report_table
  end

  it 'opens master results from a single-word special column despite hidden target buttons' do
    modal = open_report_result_link(@matching_master.id.to_s, column: "search_reports_#{@simple_target.id}_player")
    expect_report_modal_masters(@matching_master, @excluded_master)
    expect(modal).to have_content("Search results for #{@matching_master.id}")
    expect(modal).to have_no_selector('form')
  end

  it 'uses the complete underscored search attribute from a special column' do
    modal = open_report_result_link(@matching_master.id.to_s,
                                    column: "search_reports_#{@underscore_target.id}_player_record_id")
    expect_report_modal_masters(@matching_master, @excluded_master)
    expect(modal).to have_no_selector('form')
  end

  it 'opens a report criteria form and filtered table from an ordinary URL column' do
    modal = open_report_result_link('View table')
    expect(modal).to have_content(@table_target.name)
    within(modal) { click_button 'list' }
    finish_page_loading
    expect(modal).to have_content("Matched master #{@matching_master.id}")
    expect(modal).to have_no_content("Matched master #{@excluded_master.id}")
    expect(modal).to have_no_selector('.master-result')
  end

  it 'automatically opens a filtered master records list from an ordinary URL column' do
    modal = open_report_result_link('View masters')
    expect(modal).to have_content(@search_target.name)
    expect_report_modal_masters(@matching_master, @excluded_master)
  end

  def create_modal_target(field, report_type: 'regular_report', options: '')
    create_modal_report(
      name: "Modal #{report_type} #{field}",
      sql: <<~SQL.squish,
        SELECT id AS master_id, 'Matched master ' || id AS matched_record
        FROM masters
        WHERE id = :#{field}
      SQL
      search_attrs: <<~YAML,
        #{field}:
          number:
            multiple: single
      YAML
      report_type:,
      options:
    )
  end

  def create_modal_report(name:, sql:, search_attrs: '', options: '', report_type: 'regular_report')
    report = Report.create!(
      current_admin: @admin,
      name: "#{name} #{SecureRandom.hex(4)}",
      sql:,
      search_attrs:,
      options:,
      report_type:,
      disabled: false,
      searchable: false,
      auto: false
    )
    @modal_reports << report
    report
  end
end
