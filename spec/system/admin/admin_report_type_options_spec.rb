# frozen_string_literal: true

# Covers the admin-facing report type labels, searchable label, auto toggle,
# and generated options skeleton for issue #1522.

require 'rails_helper'

describe 'admin report type options', js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include AdminActionsSetup
  include AdminFeatureSupport
  include FeatureSupport
  include ModelSupport

  before(:all) do
    SetupHelper.feature_setup
    make_an_admin

    @report = create_test_report('Report type test', report_type: 'report', auto: true)
    @regular_report = create_test_report('Legacy type test', report_type: 'regular_report')
    @reports = [@report, @regular_report]
  end

  after(:all) do
    @reports&.each do |report|
      report.update!(disabled: true, current_admin: @admin) if report.persisted?
    end
  end

  before(:each) do
    admin_sign_in_with_2fa
  end

  it 'uses the display labels in the admin item list and report type select' do
    visit '/admin/reports'
    finish_page_loading

    expect(page).to have_css("#admin-item-#{@report.id} td:nth-of-type(5)", text: 'report')
    expect(page).to have_css(
      "#admin-item-#{@regular_report.id} td:nth-of-type(5)", text: '(deprecated) regular report'
    )

    open_report_edit_form(@report)
    type_select = find('#report_report_type', visible: :all)
    type_options = type_select.all('option').map { |option| [option.text.strip, option.value] }
    expect(type_options).to include(
      ['report', 'report'],
      ['count', 'count'],
      ['(deprecated) regular report', 'regular_report'],
      ['(deprecated) report and list records', 'search']
    )
    expect(page).to have_css('label[for="report_searchable"]', text: 'show as search panel')
  end

  it 'hides the automatic-run checkbox group for report type and toggles it without clearing the value' do
    visit '/admin/reports'
    finish_page_loading
    open_report_edit_form(@report)

    expect(page).to have_css('.report-auto-options.hidden', visible: :all)
    expect(find('#report_auto', visible: :all)).to be_checked
    select_admin_field('report_type', '(deprecated) regular report')
    expect(page).to have_css('.report-auto-options:not(.hidden)', visible: true)
    expect(find('#report_auto', visible: :all)).to be_checked

    select_admin_field('report_type', 'report')
    expect(page).to have_css('.report-auto-options.hidden', visible: :all)
    expect(find('#report_auto', visible: :all)).to be_checked
  end

  it 'pre-fills a new report form with the all-null non-legacy options skeleton' do
    visit '/admin/reports'
    finish_page_loading
    within '.admin-index-actions' do
      find('a.add-item-button').click
    end
    expect(page).to have_css('.admin-edit-form', wait: 10)

    options_text = find('textarea[name$="[options]"]', visible: :all).value
    options = YAML.safe_load(options_text, permitted_classes: [], permitted_symbols: [], aliases: true)
    view_options = OptionConfigs::ReportOptions::ViewOptions.configure_with_items - OptionConfigs::ReportOptions::LEGACY_VIEW_OPTIONS

    expect(options.fetch('view_options').keys.map(&:to_sym)).to eq(view_options)
    expect(options.fetch('search_panel_options').keys.map(&:to_sym))
      .to eq(OptionConfigs::ReportOptions::SearchPanelOptions.configure_with_items)
    expect(options.fetch('embedded_options').keys.map(&:to_sym))
      .to eq(OptionConfigs::ReportOptions::EmbeddedOptions.configure_with_items)
    expect(options.values.flat_map(&:values).compact).to be_empty
  end

  private

  def create_test_report(name, report_type:, auto: false)
    Report.create!(
      current_admin: @admin,
      name: "Issue 1522 #{name} #{SecureRandom.hex(4)}",
      description: 'Report type admin characterization',
      sql: 'select 1 as result_value',
      search_attrs: '',
      disabled: false,
      report_type:,
      auto:,
      searchable: false,
      position: nil
    )
  end

  def open_report_edit_form(report)
    within "#admin-item-#{report.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end
    expect(page).to have_css('#report_report_type', wait: 10)
    finish_page_loading
  end
end
