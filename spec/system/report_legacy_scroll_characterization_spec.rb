# frozen_string_literal: true

# Characterizes legacy report scrolling and result-navigation controls across
# report pages, searchable report panels, and user-facing embedded report modals.

require 'rails_helper'

describe 'legacy report result scrolling', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include FeatureSupport
  include MasterSupport
  include ModelSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    @admin, = create_admin

    @user, @good_password = create_user
    @good_email = @user.email
    setup_user_report_access
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

  it 'scrolls manual table results into view and toggles the back and show buttons' do
    visit report_path(@manual_rows_report)
    finish_page_loading

    click_report_button('table')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)
    expect(page).to have_css('.show-results-btn', visible: false)

    click_link 'back to search form'
    wait_for_ui_to_settle
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    # CURRENT BEHAVIOUR (suspected bug, see #1522): the show-results link stays
    # hidden after returning to the form, so the control is not available to click.
    expect(page).to have_css('.show-results-btn', visible: false)
    expect(page.evaluate_script("Math.abs(document.querySelector('#body-top').getBoundingClientRect().top)")).to be < 30
  end

  it 'does not scroll manual results when no_results_scroll is enabled' do
    visit report_path(@no_scroll_rows_report)
    finish_page_loading

    click_report_button('table')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect(page).to have_css('.report-results-block.no_results_scroll')
    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect_results_not_at_top
  end

  it 'returns to the form for zero-row results and leaves only the show-results control visible' do
    visit report_path(@zero_rows_report)
    finish_page_loading

    click_report_button('table')
    expect(page).to have_css('.report-results-block', wait: 15)
    wait_for_ui_to_settle

    expect_results_not_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    expect(page).to have_css('.show-results-btn', visible: true)
  end

  it 'does not scroll after a report-page auto-submit on change through the table button' do
    # TRACE DISCREPANCY: the trace predicts that this table-button auto-submit scrolls.
    # The current form also clicks the hidden auto-submitter, which marks the request
    # as automatic and leaves the results below the viewport.
    visit report_path(@change_submit_report)
    finish_page_loading

    fill_in 'search_attrs[search_text]', with: 'change trigger'
    find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    wait_for_ui_to_settle
    expect(page).to have_css('.report-results-block', wait: 15)
    expect(page).to have_content('1', wait: 15)

    expect_results_not_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: false)
    # CURRENT BEHAVIOUR (suspected bug, see #1522): the show control is rendered
    # but remains hidden after this change-triggered submission.
    expect(page).to have_css('.show-results-btn', visible: false)
  end

  it 'auto-submits searchable full-page criteria even when report_auto_submit_on_change is false' do
    # CURRENT BEHAVIOUR (suspected bug, see #1522): the searchable report keeps
    # a hidden auto-submitter, so false does not prevent change-triggered submits.
    visit report_path(@change_disabled_searchable_report)
    finish_page_loading

    table_button = find('#report-form-submit-btn')
    hidden_submitter = find('#report-form-auto-submitter-btn', visible: :all)
    expect(table_button[:class]).not_to include('auto-submitter')
    expect(hidden_submitter[:class]).to include('hidden', 'auto-submitter')

    page.execute_script(<<~JS)
      window.issue1522HiddenAutoClicks = 0;
      window.issue1522FormSubmits = 0;
      window.issue1522ScrollAtSubmit = null;
      $(document).on('click.issue1522Hidden', '#report-form-auto-submitter-btn', function() {
        window.issue1522HiddenAutoClicks += 1;
      });
      $(document).on('submit.issue1522Hidden', '#report_query_form', function() {
        window.issue1522FormSubmits += 1;
        window.issue1522ScrollAtSubmit = window.scrollY;
      });
    JS
    fill_in 'search_attrs[search_text]', with: 'change trigger'
    find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    wait_for_ui_to_settle

    expect(page.evaluate_script('window.issue1522HiddenAutoClicks')).to eq(1)
    expect(page.evaluate_script('window.issue1522FormSubmits')).to eq(1)
    expect(page.evaluate_script('window.issue1522ScrollAtSubmit')).not_to be_nil
    expect(page.evaluate_script('window.scrollY')).to be < 30
  end

  it 'scrolls after force_run auto-clicks the report-page table button on load' do
    # CURRENT BEHAVIOUR (suspected bug, see #1522): the auto-run click is not
    # marked as an auto-submit, so a non-empty result is scrolled into view.
    visit report_path(@force_run_report, force_run: 'true')
    finish_page_loading

    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)
  end

  it 'auto-runs a searchable report panel without scrolling to the master results' do
    visit '/masters/search'
    finish_page_loading

    click_report_tab(@panel_auto_report.name)
    panel_selector = "#master-report-#{@panel_auto_report.alt_resource_name}"
    expect(page).to have_css("#{panel_selector}.in form.search_report", wait: 15)
    expect(page).to have_css("#{panel_selector} .search_count_reports .search_count", text: /[1-9]\d*/, wait: 15)
    wait_for_ui_to_settle

    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect_master_results_not_at_top
  end

  it 'does not render a run button in a searchable regular-report panel even when no_results_scroll is enabled' do
    visit '/masters/search'
    finish_page_loading
    initial_scroll = page.evaluate_script('window.scrollY')

    click_report_tab(@regular_searchable_panel_report.name)
    panel_selector = "#master-report-#{@regular_searchable_panel_report.alt_resource_name}"
    expect(page).to have_css("#{panel_selector}.in form.search_report", wait: 15)
    expect(page).not_to have_css("#{panel_selector} form.search_report [type='submit']")
    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect(page.evaluate_script('window.scrollY')).to eq(initial_scroll)
  end

  it 'does not scroll when a user manually runs a report from a search panel' do
    visit '/masters/search'
    finish_page_loading

    click_report_tab(@panel_manual_search_report.name)
    panel_selector = "#master-report-#{@panel_manual_search_report.alt_resource_name}"
    expect(page).to have_css("#{panel_selector}.in form.search_report", wait: 15)
    initial_scroll = page.evaluate_script('window.scrollY')

    within panel_selector do
      click_button 'search'
    end
    expect(page).to have_css('.search_count_reports .search_count', text: /[1-9]\d*/, wait: 15)
    wait_for_ui_to_settle

    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect_master_results_not_at_top
    expect((page.evaluate_script('window.scrollY') - initial_scroll).abs).to be < 100
  end

  it 'uses master-list search and table results for a search report on its full page' do
    visit report_path(@fullpage_search_report)
    finish_page_loading

    click_report_button('search')
    expect(page).to have_css('#master_results_block .master-result', wait: 15)
    expect(page).to have_content(@master.id.to_s)
    wait_for_ui_to_settle

    expect(page).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    expect_master_results_not_at_top

    visit report_path(@fullpage_search_report)
    finish_page_loading
    click_report_button('table')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect_results_at_top
    expect(page).to have_css('.back-to-search-form-btn', visible: true)
  end

  it 'opens user-facing embedded report forms with legacy buttons and no result navigation controls' do
    open_user_embedded_report('Regular report')

    within active_report_modal do
      table_button = find('#report-form-submit-btn')
      expect([table_button.text.strip, table_button[:value]]).to eq ['list', 'table']
      expect(table_button[:class]).to include('auto-submitter')
      expect(page).not_to have_css('[name="format"]')
    end
    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(0)

    within active_report_modal do
      click_button 'list'
    end
    expect(active_report_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect_modal_results_without_navigation
    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(1)

    open_user_embedded_report('Search report')
    within active_report_modal do
      search_button = find('#report_query_form input[type="submit"][value="search"]')
      table_button = find('#report_query_form button[type="submit"][value="table"]')
      expect(search_button.value).to eq('search')
      expect(search_button[:class]).to include('auto-submitter')
      expect(table_button.text.strip).to eq('table')
      expect(table_button[:class]).not_to include('auto-submitter', 'auto-run')
    end
    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(0)
    expect(active_report_modal).not_to have_css('.back-to-search-form-btn, .show-results-btn')
  end

  it 'auto-runs embedded reports for auto and force_run links without scrolling the page' do
    # CURRENT BEHAVIOUR (suspected bug, see #1522): both load triggers submit,
    # but embedded results do not scroll and render no back/show controls.
    open_user_embedded_report('Auto report')
    expect(active_report_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(1)
    expect(active_report_modal).to have_css('#report-form-submit-btn.auto-run')
    expect_modal_results_without_navigation

    force_run_context = open_user_embedded_report('Force-run report')
    expect(force_run_context[:href]).to include('force_run=true')
    expect(active_report_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle
    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(1)
    expect(active_report_modal).to have_css('#report-form-submit-btn.auto-run')
    expect_modal_results_without_navigation
  end

  it 'auto-submits changed criteria in the user-facing embedded modal without scrolling' do
    open_user_embedded_report('Change report')
    within active_report_modal do
      expect(find('#report-form-submit-btn')[:class]).to include('auto-submitter')
      fill_in 'search_attrs[search_text]', with: 'change trigger'
      find('input[name="search_attrs[search_text]"]').send_keys(:tab)
    end
    expect(active_report_modal).to have_css('#embed_results_block .report-results-table-block table.report-table tbody tr', wait: 15)
    wait_for_ui_to_settle

    expect(page.evaluate_script('window.issue1522EmbeddedSubmits')).to eq(1)
    expect_modal_results_without_navigation
  end

  it 'keeps count-only results hidden while rendering hidden back-to-form controls' do
    # CURRENT BEHAVIOUR (suspected bug, see #1522): the count-only results block
    # hides the back/show controls through its parent rather than omitting them.
    visit report_path(@count_only_report)
    finish_page_loading

    click_report_button('count')
    expect(page).to have_css('.report-results-block.hidden', visible: false, wait: 15)
    wait_for_ui_to_settle

    back_button = find('.back-to-search-form-btn', visible: :all)
    show_button = find('.show-results-btn', visible: :all)
    expect(back_button).to be_present
    expect(show_button).to be_present
    expect(back_button.visible?).to be(false)
    expect(show_button.visible?).to be(false)
  end

  private

  def setup_user_report_access
    setup_access :view_reports, resource_type: :general, access: :read, user: @user
  end

  def create_reports
    @reports = []
    @manual_rows_report = create_report('Manual rows', sql: master_row_sql, description: scroll_description)
    @no_scroll_rows_report = create_report(
      'No scroll rows', sql: master_row_sql, options: { no_results_scroll: true }
    )
    @zero_rows_report = create_report('Zero rows', sql: 'select id as master_id from masters where false')
    @change_submit_report = create_report(
      'Change submit', sql: 'select 1 as master_id',
                       searchable: true, search_attrs: search_text_attrs,
                       options: { report_auto_submit_on_change: true }, description: scroll_description
    )
    @change_disabled_searchable_report = create_report(
      'Change disabled searchable', sql: 'select 1 as result_value',
                                    searchable: true, search_attrs: search_text_attrs,
                                    options: { report_auto_submit_on_change: false }, description: scroll_description
    )
    @force_run_report = create_report('Force run', sql: master_row_sql, description: scroll_description)
    @panel_auto_report = create_report('Panel auto', sql: master_row_sql, report_type: 'search', auto: true, searchable: true)
    @regular_searchable_panel_report = create_report(
      'Regular panel', sql: master_row_sql, searchable: true, options: { no_results_scroll: true }
    )
    @panel_manual_search_report = create_report(
      'Manual panel', sql: master_row_sql, report_type: 'search', searchable: true
    )
    @fullpage_search_report = create_report(
      'Full-page search', sql: master_row_sql, report_type: 'search', searchable: true,
                          description: scroll_description
    )
    @count_only_report = create_report('Count only', sql: master_row_sql)

    @modal_regular_report = create_report('Modal regular', sql: 'select 1 as result_value')
    @modal_search_report = create_report('Modal search', sql: 'select 1 as master_id', report_type: 'search')
    @modal_auto_report = create_report('Modal auto', sql: 'select 1 as result_value', auto: true)
    @modal_force_run_report = create_report('Modal force run', sql: 'select 1 as result_value')
    @modal_change_report = create_report(
      'Modal change', sql: 'select 1 as result_value', search_attrs: search_text_attrs,
                      options: { report_auto_submit_on_change: true }
    )

    @embedded_launcher_report = create_report(
      'Embedded launcher', sql: embedded_launcher_sql,
                           extra_options: {
                             column_options: {
                               show_as: {
                                 regular_link: 'embedded_report',
                                 search_link: 'embedded_report',
                                 auto_link: 'embedded_report',
                                 force_run_link: 'embedded_report',
                                 change_link: 'embedded_report'
                               }
                             }
                           }
    )
  end

  def create_report(label, sql:, report_type: 'regular_report', auto: false, searchable: false,
                    search_attrs: '', options: {}, extra_options: {},
                    description: 'Report scrolling characterization')
    configured_options = extra_options.deep_stringify_keys
    configured_options['view_options'] = options.stringify_keys if options.any?
    options_text = configured_options.to_yaml if configured_options.any?
    report = Report.create!(
      current_admin: @admin,
      name: "Issue 1522 #{label} #{SecureRandom.hex(4)}",
      description:,
      sql:,
      search_attrs:,
      options: options_text,
      disabled: false,
      report_type:,
      auto:,
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

  def embedded_launcher_sql
    regular_path = report_path(@modal_regular_report)
    search_path = report_path(@modal_search_report)
    auto_path = report_path(@modal_auto_report)
    force_run_path = report_path(@modal_force_run_report)
    change_path = report_path(@modal_change_report)

    <<~SQL.squish
      SELECT '[Regular report](#{regular_path})' AS regular_link,
             '[Search report](#{search_path})' AS search_link,
             '[Auto report](#{auto_path})' AS auto_link,
             '[Force-run report](#{force_run_path}' || chr(63) || 'force_run=true)' AS force_run_link,
             '[Change report](#{change_path})' AS change_link
    SQL
  end

  def open_user_embedded_report(label)
    visit '/reports'
    finish_page_loading
    visit report_path(@embedded_launcher_report)
    finish_page_loading
    click_report_button('table')
    expect(page).to have_css('.report-results-table-block table.report-table tbody tr', wait: 15)
    finish_page_loading
    wait_for_ui_to_settle
    expect(page).to have_css('a[data-preprocessor="embedded_report"]', text: label, wait: 15)

    link = find('a[data-preprocessor="embedded_report"]', text: label)
    scroll_into_view(link)
    track_embedded_report_submits
    link.click
    expect(page).to have_css('.modal form.search_report', visible: true, wait: 30)
    wait_for_ui_to_settle(timeout: 30)
    expect(active_report_modal).to have_css('#report_query_form')
    finish_page_loading
    wait_for_ui_to_settle

    { href: link[:href] }
  end

  def track_embedded_report_submits
    page.execute_script(<<~JS)
      window.issue1522EmbeddedSubmits = 0;
      $(document).on('submit.issue1522', '.modal form.search_report', function() {
        window.issue1522EmbeddedSubmits += 1;
      });
    JS
  end

  def active_report_modal
    modal = all('.modal', visible: true, wait: 30).find do |candidate|
      candidate.has_css?('form.search_report', visible: true, wait: 0)
    end
    expect(modal).not_to be_nil, 'Expected a visible modal containing the embedded report form'
    modal
  end

  def expect_modal_results_without_navigation
    modal = active_report_modal
    expect(modal).to have_css('#embed_results_block .report-results-block.no_results_scroll', wait: 15)
    expect(modal).not_to have_css('.back-to-search-form-btn, .show-results-btn')
    result_top = page.evaluate_script(<<~JS)
      (() => {
        const modal = Array.from(document.querySelectorAll('.modal'))
          .find((candidate) => candidate.querySelector('form.search_report'));
        return modal.querySelector('#embed_results_block .report-results-block').getBoundingClientRect().top;
      })()
    JS
    expect(result_top).to be > 30
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

  def scroll_description
    ("A paragraph above the report results makes the target scrollable.\n\n" * 35)
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

  def expect_results_not_at_top
    expect(page.evaluate_script("Math.abs(document.querySelector('.report-results-block').getBoundingClientRect().top)")).to be > 30
  end

  def expect_master_results_not_at_top
    expect(page.evaluate_script("Math.abs(document.querySelector('#master_results_block').getBoundingClientRect().top)")).to be > 30
  end
end
