# frozen_string_literal: true

# Verifies scrolling, result-navigation controls, context buttons, and the
# auto-submit triggers for the new report type without altering legacy specs.

require 'rails_helper'

describe 'report type report result behavior', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include FeatureSupport
  include MasterSupport
  include ModelSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    @user, @good_password = create_user
    @good_email = @user.email
    setup_access :view_reports, resource_type: :general, access: :read, user: @user
    @master = create_master(@user)
    create_reports
  end

  after(:all) do
    @reports&.each do |report|
      report.update!(disabled: true, current_admin: @admin) if report.persisted?
    end
  end

  before(:each) do
    login
  end

  it 'scrolls manual page results and leaves the show-results control usable after returning to the form' do
    visit report_path(@manual_rows_report)
    finish_page_loading

    click_report_button('report')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)
    expect(page).to have_css('.show-results-btn', visible: false)

    click_link 'back to search form'
    wait_for_ui_to_settle
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    expect(page).to have_css('.show-results-btn', visible: true)

    click_link 'show all results'
    wait_for_ui_to_settle
    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)
    expect(page).to have_css('.show-results-btn', visible: false)
  end

  it 'returns to the form for manual zero-row results unless no-report-scroll is enabled' do
    visit report_path(@manual_zero_rows_report)
    finish_page_loading
    initial_scroll = page.evaluate_script('window.scrollY')

    click_report_button('report')
    expect(page).to have_css('.report-results-block', wait: 15)
    wait_for_ui_to_settle

    expect(page).not_to have_css('.report-results-table-block table.report-table tbody tr')
    results_top = page.evaluate_script("Math.abs(document.querySelector('.report-results-block').getBoundingClientRect().top)")
    expect(results_top).to be > 30
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    expect(page).to have_css('.show-results-btn', visible: true)
    expect((page.evaluate_script('window.scrollY') - initial_scroll).abs).to be < 30

    visit report_path(@manual_zero_rows_no_scroll_report)
    finish_page_loading
    initial_scroll = page.evaluate_script('window.scrollY')
    click_report_button('report')
    expect(page).to have_css('.report-results-block.no_results_scroll', wait: 15)
    wait_for_ui_to_settle

    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect((page.evaluate_script('window.scrollY') - initial_scroll).abs).to be < 30
  end

  it 'submits table results when Enter is pressed in a report-page criteria field' do
    visit report_path(@enter_submit_report)
    finish_page_loading

    fill_in 'search_attrs[search_text]', with: @master.id.to_s
    find('input[name="search_attrs[search_text]"]').send_keys(:enter)
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    expect(page).not_to have_css('#master_results_block .master-result')
  end

  it 'submits list-records on Enter when the report button is hidden and the list button is shown' do
    visit report_path(@enter_list_records_report)
    finish_page_loading

    fill_in 'search_attrs[search_text]', with: @master.id.to_s
    find('input[name="search_attrs[search_text]"]').send_keys(:enter)
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    expect(page).not_to have_css('.report-results-table-block table.report-table')
  end

  it 'respects nil, false, and true no-report-scroll settings and omits count-only navigation controls' do
    visit report_path(@manual_false_scroll_report)
    finish_page_loading
    click_report_button('report')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)

    visit report_path(@no_scroll_rows_report)
    finish_page_loading
    initial_scroll = page.evaluate_script('window.scrollY')
    click_report_button('report')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect(page).to have_css('.report-results-block.no_results_scroll')
    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect((page.evaluate_script('window.scrollY') - initial_scroll).abs).to be < 30

    visit report_path(@count_only_report)
    finish_page_loading
    click_report_button('count')
    expect(page).to have_css('.report-results-block.hidden', visible: false, wait: 15)
    wait_for_ui_to_settle
    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
  end

  it 'does not scroll or change result-navigation controls for auto-load, force-run, or zero-row submissions' do
    [
      [@auto_load_rows_report, {}],
      [@auto_load_zero_rows_report, {}],
      [@force_run_report, { force_run: 'true' }]
    ].each do |report, query|
      visit report_path(report, **query)
      finish_page_loading
      expect(page).to have_css('.report-results-block', wait: 15)
      wait_for_ui_to_settle

      expect(page.evaluate_script('window.scrollY')).to be < 30
      expect(page).to have_css('.back-to-search-form-btn', visible: true)
      expect(page).to have_css('.show-results-btn', visible: false)
    end
  end

  it 'keeps the show-results control visible and usable after an auto-submit-on-change' do
    visit report_path(@auto_change_report)
    finish_page_loading

    click_report_button('report')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    click_link 'back to search form'
    wait_for_ui_to_settle
    expect(page).to have_css('.show-results-btn', visible: true)

    page.execute_script(<<~JS)
      window.issue1522ReportTypeSubmitCount = 0;
      $('#report_query_form').on('submit.issue1522ReportType', function() {
        window.issue1522ReportTypeSubmitCount += 1;
      });
    JS
    fill_in 'search_attrs[search_text]', with: '1'
    find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    wait_for_ui_to_settle
    expect(page).to have_css('.report-results-block', wait: 15)
    wait_for_ui_to_settle

    expect(page.evaluate_script('window.issue1522ReportTypeSubmitCount')).to eq(1)
    expect(page.evaluate_script('window.scrollY')).to be < 30
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    expect(page).to have_css('.show-results-btn', visible: true)

    click_link 'show all results'
    wait_for_ui_to_settle
    expect_results_at_top
  end

  it 'renders searchable report tabs and keeps manual, load, and change panel submissions from scrolling' do
    visit '/masters/search'
    finish_page_loading

    expect(page).to have_css(
      "#expand-searchable-report-#{@panel_manual_report.alt_resource_name}"
    )
    expect(page).to have_css(
      "#expand-searchable-report-#{@panel_collapse_report.alt_resource_name}.prevent-list-collapse"
    )

    click_report_tab(@panel_manual_report.name)
    panel_selector = "#master-report-#{@panel_manual_report.alt_resource_name}"
    expect(page).to have_css("#{panel_selector}.in form.search_report", wait: 15)
    initial_scroll = page.evaluate_script('window.scrollY')
    within panel_selector do
      click_button 'search'
    end
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    wait_for_ui_to_settle
    expect((page.evaluate_script('window.scrollY') - initial_scroll).abs).to be < 100

    auto_panel = "#master-report-#{@panel_auto_load_report.alt_resource_name}"
    page.execute_script(<<~JS)
      window.issue1522PanelAutoSubmits = 0;
      $(document).off('submit.issue1522PanelAuto');
      $(document).on('submit.issue1522PanelAuto', '#{auto_panel} form.search_report', function() {
        window.issue1522PanelAutoSubmits += 1;
      });
    JS
    click_report_tab(@panel_auto_load_report.name)
    expect(page).to have_css("#{auto_panel}.in form.search_report", wait: 15)
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522PanelAutoSubmits')).to eq(1)
    expect(page.evaluate_script('window.scrollY')).to be < 100

    click_report_tab(@panel_auto_change_report.name)
    change_panel = "#master-report-#{@panel_auto_change_report.alt_resource_name}"
    expect(page).to have_css("#{change_panel}.in form.search_report", wait: 15)
    page.execute_script(<<~JS)
      window.issue1522PanelScrollAtSubmit = null;
      $("#{change_panel} form.search_report").on('submit.issue1522Panel', function() {
        window.issue1522PanelScrollAtSubmit = window.scrollY;
      });
    JS
    within change_panel do
      fill_in 'search_attrs[search_text]', with: 'panel change'
      find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    end
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    wait_for_ui_to_settle
    submit_scroll = page.evaluate_script('window.issue1522PanelScrollAtSubmit')
    expect(submit_scroll).not_to be_nil
    expect((page.evaluate_script('window.scrollY') - submit_scroll).abs).to be < 30

    visit '/masters/search'
    finish_page_loading
    force_tab_id = "#expand-searchable-report-#{@panel_force_run_report.alt_resource_name}"
    force_tab = find(force_tab_id)
    force_href = force_tab[:href]
    force_href += force_href.include?('?') ? '&force_run=true' : '?force_run=true'
    page.execute_script('arguments[0].setAttribute("href", arguments[1]);', force_tab, force_href)
    force_panel = "#master-report-#{@panel_force_run_report.alt_resource_name}"
    page.execute_script(<<~JS)
      window.issue1522PanelForceRunSubmits = 0;
      $(document).off('submit.issue1522PanelForceRun');
      $(document).on('submit.issue1522PanelForceRun', '#{force_panel} form.search_report', function() {
        window.issue1522PanelForceRunSubmits += 1;
      });
    JS
    click_report_tab(@panel_force_run_report.name)
    expect(page).to have_css("#{force_panel}.in form.search_report", wait: 15)
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522PanelForceRunSubmits')).to eq(1)
    expect(page.evaluate_script('window.scrollY')).to be < 100
  end

  it 'renders only the report button in user-facing embedded modals for manual and automatic triggers' do
    manual_modal = open_embedded_report('Manual embedded report')
    expect(manual_modal).to have_css('#report-form-submit-btn', text: 'report')
    expect(manual_modal).not_to have_css('[name="format"], [name="commit"][value="search"], [name="commit"][value="count"]')
    page_scroll = page.evaluate_script('window.scrollY')
    within manual_modal do
      click_button 'report'
    end
    expect(manual_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect_modal_without_navigation
    expect(page.evaluate_script('window.scrollY')).to eq(page_scroll)
    dismiss_all_modals

    auto_modal = open_embedded_report('Auto embedded report')
    expect(auto_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect_modal_without_navigation
    expect(page.evaluate_script('window.issue1522EmbeddedReportSubmits')).to eq(1)
    within auto_modal do
      fill_in 'search_attrs[search_text]', with: 'embedded change'
      find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    end
    expect(auto_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522EmbeddedReportSubmits')).to eq(2)
    expect_modal_without_navigation
    dismiss_all_modals

    force_modal = open_embedded_report('Force-run embedded report')
    expect(force_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522EmbeddedReportSubmits')).to eq(1)
    expect_modal_without_navigation
  end

  private

  def create_reports
    @reports = []
    @manual_rows_report = create_report('Manual rows', sql: master_row_sql)
    @enter_submit_report = create_report(
      'Enter submits table', sql: master_row_sql, search_attrs: search_text_attrs
    )
    @enter_list_records_report = create_report(
      'Enter submits list records', sql: master_row_sql, search_attrs: search_text_attrs,
                                    view_options: { hide_report_button: true, show_list_records_button: true }
    )
    @manual_zero_rows_report = create_report(
      'Manual zero rows', sql: 'select id as master_id from masters where false'
    )
    @manual_zero_rows_no_scroll_report = create_report(
      'Manual zero rows no scroll', sql: 'select id as master_id from masters where false',
                                    view_options: { no_report_results_scroll: true }
    )
    @manual_false_scroll_report = create_report(
      'Manual false scroll', sql: master_row_sql, view_options: { no_report_results_scroll: false }
    )
    @no_scroll_rows_report = create_report(
      'No scroll rows', sql: master_row_sql, view_options: { no_report_results_scroll: true }
    )
    @count_only_report = create_report('Count only', sql: master_row_sql)
    @auto_load_rows_report = create_report(
      'Auto load rows', sql: master_row_sql, view_options: { auto_submit_on_load: true }
    )
    @auto_load_zero_rows_report = create_report(
      'Auto load zero rows', sql: 'select id as master_id from masters where false',
                             view_options: { auto_submit_on_load: true }
    )
    @auto_change_report = create_report(
      'Auto change', sql: 'select 1 as result_value', search_attrs: search_text_attrs,
                     view_options: { auto_submit_on_change: true }
    )
    @force_run_report = create_report('Force run', sql: master_row_sql)

    @panel_manual_report = create_report('Panel manual', sql: master_row_sql, searchable: true)
    @panel_collapse_report = create_report(
      'Panel prevent collapse', sql: master_row_sql, searchable: true,
                                search_panel_options: { prevent_collapse_for_search_panel_results: true }
    )
    @panel_auto_load_report = create_report(
      'Panel auto load', sql: master_row_sql, searchable: true,
                         search_panel_options: { auto_submit_on_load: true }
    )
    @panel_auto_change_report = create_report(
      'Panel auto change', sql: master_row_sql, searchable: true, search_attrs: search_text_attrs,
                           search_panel_options: { auto_submit_on_change: true }
    )
    @panel_force_run_report = create_report('Panel force run', sql: master_row_sql, searchable: true)

    @embedded_manual_report = create_report('Embedded manual', sql: master_row_sql)
    @embedded_auto_report = create_report(
      'Embedded auto', sql: master_row_sql, search_attrs: search_text_attrs,
                       embedded_options: { auto_submit_on_load: true, auto_submit_on_change: true }
    )
    @embedded_force_report = create_report('Embedded force', sql: master_row_sql)
    @embedded_launcher_report = create_report(
      'Embedded launcher', sql: embedded_launcher_sql, report_type: 'regular_report',
                           options: { column_options: { show_as: {
                             manual_link: 'embedded_report', auto_link: 'embedded_report',
                             force_run_link: 'embedded_report'
                           } } }
    )
  end

  def create_report(name, sql:, report_type: 'report', searchable: false, search_attrs: '',
                    view_options: {}, search_panel_options: {}, embedded_options: {}, options: {})
    configuration = options.deep_stringify_keys
    configuration['view_options'] = view_options.stringify_keys if view_options.any?
    configuration['search_panel_options'] = search_panel_options.stringify_keys if search_panel_options.any?
    configuration['embedded_options'] = embedded_options.stringify_keys if embedded_options.any?
    report = Report.create!(
      current_admin: @admin,
      name: "Issue 1522 #{name} #{SecureRandom.hex(4)}",
      description: 'Report type scrolling and auto-submit behavior',
      sql:,
      search_attrs:,
      options: configuration.empty? ? nil : configuration.to_yaml,
      disabled: false,
      report_type:,
      auto: false,
      searchable:,
      position: nil
    )
    Admin::UserAccessControl.create!(
      app_type: @user.app_type,
      access: :read,
      resource_type: :report,
      resource_name: report.alt_resource_name,
      current_admin: @admin,
      user: @user
    )
    @reports << report
    report
  end

  def master_row_sql
    "select id as master_id from masters where id = #{@master.id}"
  end

  def search_text_attrs
    <<~YAML
      search_text:
        text:
          all: true
          multiple: single
          disabled: false
    YAML
  end

  def embedded_launcher_sql
    manual_path = report_path(@embedded_manual_report)
    auto_path = report_path(@embedded_auto_report)
    force_run_path = report_path(@embedded_force_report)

    <<~SQL.squish
      SELECT '[Manual embedded report](#{manual_path})' AS manual_link,
             '[Auto embedded report](#{auto_path})' AS auto_link,
             '[Force-run embedded report](#{force_run_path}' || chr(63) || 'force_run=true)' AS force_run_link
    SQL
  end

  def open_embedded_report(label)
    visit '/reports'
    finish_page_loading
    visit report_path(@embedded_launcher_report)
    finish_page_loading
    click_report_button('table')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    link = find('a[data-preprocessor="embedded_report"]', text: label, wait: 15)
    scroll_into_view(link)
    page.execute_script(<<~JS)
      window.issue1522EmbeddedReportSubmits = 0;
      $(document).off('submit.issue1522EmbeddedReport', '.modal form.search_report');
      $(document).on('submit.issue1522EmbeddedReport', '.modal form.search_report', function() {
        window.issue1522EmbeddedReportSubmits += 1;
      });
    JS
    link.click
    expect(page).to have_css('.modal form.search_report', visible: true, wait: 30)
    wait_for_ui_to_settle(timeout: 30)
    active_report_modal
  end

  def active_report_modal
    modal = all('.modal', visible: true, wait: 30).find do |candidate|
      candidate.has_css?('form.search_report', visible: true, wait: 0)
    end
    expect(modal).not_to be_nil, 'Expected a visible modal containing the embedded report form'
    modal
  end

  def expect_modal_without_navigation
    modal = active_report_modal
    expect(modal).to have_css('#embed_results_block .report-results-block.no_results_scroll', wait: 15)
    expect(modal).not_to have_css('.back-to-search-form-btn, .show-results-btn')
  end

  def click_report_button(label)
    within '#report_query_form' do
      click_button label
    end
  end

  def expect_results_at_top
    expect(page.evaluate_script("Math.abs(document.querySelector('.report-results-block').getBoundingClientRect().top)")).to be < 30
    expect(page.evaluate_script('window.scrollY')).to be > 0
  end
end
