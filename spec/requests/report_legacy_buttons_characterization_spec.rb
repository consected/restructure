# frozen_string_literal: true

# Characterizes the legacy report button matrix, including its context-specific
# labels/classes and the distinct list, table, count, and embedded result paths.

require 'rails_helper'

RSpec.describe 'Legacy report button rendering', type: :request do
  include MasterSupport
  include ModelSupport

  before(:all) do
    SetupHelper.feature_setup
  end

  before do
    @admin, = create_admin
    @user, = create_user
    sign_in @user, scope: :user
    setup_access :view_reports, resource_type: :general, access: :read, user: @user
    setup_access :export_csv, resource_type: :general, access: :read, user: @user
    setup_access :export_json, resource_type: :general, access: :read, user: @user
    @master = create_master(@user)
  end

  describe 'search panel buttons' do
    it 'renders a searchable legacy search report as an inline search button' do
      report = create_report(report_type: 'search', searchable: true)

      document = get_report_form(report, part: 'form', view_context: 'search')
      buttons = submit_buttons(document)

      expect(buttons.map { |button| [button[:label], button[:value]] }).to eq [['search', 'search']]
      expect(buttons.first[:classes]).to include('auto-submitter')
      expect(buttons.first[:classes]).not_to include('hidden', 'auto-run')
      expect(buttons.first[:id]).to be_nil
    end

    it 'hides an auto search-panel button unless force_show_search_button is enabled' do
      auto_report = create_report(report_type: 'search', searchable: true, auto: true)
      forced_report = create_report(
        report_type: 'search', searchable: true, auto: true,
        view_options: { force_show_search_button: true }
      )

      auto_button = submit_buttons(get_report_form(auto_report, part: 'form', view_context: 'search')).first
      forced_button = submit_buttons(get_report_form(forced_report, part: 'form', view_context: 'search')).first

      expect(auto_button[:classes]).to include('hidden', 'auto-run')
      expect(forced_button[:classes]).not_to include('hidden')
      expect(forced_button[:classes]).to include('auto-run')
    end

    it 'does not render a search-panel submit button for regular or count reports' do
      reports = [
        create_report(report_type: 'regular_report', searchable: true),
        create_report(report_type: 'count', searchable: true)
      ]

      reports.each do |report|
        expect(submit_buttons(get_report_form(report, part: 'form', view_context: 'search'))).to be_empty
      end
    end
  end

  describe 'report page and embedded buttons' do
    # TRACE DISCREPANCY: the trace groups full-page and embedded classes as
    # auto-submitter/auto-run, but an ordinary full report page gets neither;
    # the embedded first button gets auto-submitter by default.
    it 'renders search and table submissions for a full-page search report' do
      report = create_report(report_type: 'search', searchable: true)

      buttons = report_action_buttons(get_report_form(report))

      expect(buttons.map { |button| [button[:label], button[:name], button[:value]] }).to eq [
        ['search', 'commit', 'search'], ['table', 'commit', 'table']
      ]
      expect(buttons.first[:classes]).not_to include('auto-submitter', 'auto-run', 'hidden')
      expect(buttons.last[:classes]).not_to include('auto-submitter', 'auto-run', 'hidden')
      expect(buttons.pluck(:id)).to eq [nil, nil]
    end

    it 'uses search_button_label for the table button on search reports, but for the search button in the search panel' do
      report = create_report(
        report_type: 'search', searchable: true,
        view_options: { search_button_label: 'Find records' }
      )

      page_buttons = report_action_buttons(get_report_form(report))
      panel_buttons = submit_buttons(get_report_form(report, part: 'form', view_context: 'search'))

      expect(page_buttons.map { |button| [button[:label], button[:value]] }).to eq [
        ['search', 'search'], ['Find records', 'table']
      ]
      expect(panel_buttons.map { |button| [button[:label], button[:value]] }).to eq [['Find records', 'search']]
    end

    it 'renders the regular report table button and adds the hidden auto-submitter only for searchable reports' do
      searchable_report = create_report(report_type: 'regular_report', searchable: true)
      private_report = create_report(report_type: 'regular_report', searchable: false)

      searchable_buttons = report_action_buttons(get_report_form(searchable_report))
      private_buttons = report_action_buttons(get_report_form(private_report))

      expect(searchable_buttons.map { |button| [button[:label], button[:value], button[:id]] }).to eq [
        ['table', 'table', 'report-form-submit-btn'],
        ['auto-submitter', 'auto-submitter', 'report-form-auto-submitter-btn']
      ]
      expect(searchable_buttons.last[:classes]).to include('hidden', 'auto-submitter')
      expect(private_buttons.map { |button| [button[:label], button[:value], button[:id]] }).to eq [
        ['table', 'table', 'report-form-submit-btn']
      ]
    end

    it 'uses separate search and table commits for embedded search reports and renders count reports as table forms' do
      search_report = create_report(report_type: 'search', searchable: true)
      count_report = create_report(report_type: 'count')

      search_buttons = report_action_buttons(get_report_form(search_report, embed: 'true'))
      count_buttons = submit_buttons(get_report_form(count_report, embed: 'true'))

      expect(search_buttons.map { |button| [button[:label], button[:value], button[:id]] }).to eq [
        ['search', 'search', nil], ['table', 'table', nil]
      ]
      expect(search_buttons.first[:classes]).to include('auto-submitter')
      expect(search_buttons.last[:classes]).not_to include('auto-submitter', 'auto-run')
      expect(count_buttons.map { |button| [button[:label], button[:value]] }).to eq [['list', 'table']]
      expect(count_buttons.first[:classes]).to include('auto-submitter')
    end

    it 'uses list as the embedded default label and enables auto-submit on change by default' do
      report = create_report(report_type: 'regular_report', searchable: false)

      button = submit_buttons(get_report_form(report, embed: 'true')).first

      expect([button[:label], button[:name], button[:value], button[:id]]).to eq [
        'list', 'commit', 'table', 'report-form-submit-btn'
      ]
      expect(button[:classes]).to include('auto-submitter')
      expect(button[:classes]).not_to include('auto-run', 'hidden')
    end

    it 'adds auto-run to the regular table button for auto reports and force_run requests' do
      auto_report = create_report(report_type: 'regular_report', auto: true)
      forced_report = create_report(report_type: 'regular_report')

      auto_button = submit_buttons(get_report_form(auto_report)).first
      forced_button = submit_buttons(get_report_form(forced_report, force_run: 'true')).first

      expect(auto_button[:classes]).to include('auto-run')
      expect(forced_button[:classes]).to include('auto-run')
    end

    it 'attaches report_auto_submit_on_change to the table button only when enabled while retaining the hidden submitter' do
      enabled = create_report(
        report_type: 'regular_report', searchable: true,
        view_options: { report_auto_submit_on_change: true }
      )
      disabled = create_report(
        report_type: 'regular_report', searchable: true,
        view_options: { report_auto_submit_on_change: false }
      )

      enabled_buttons = submit_buttons(get_report_form(enabled))
      disabled_buttons = submit_buttons(get_report_form(disabled))

      enabled_table_button = enabled_buttons.find { |button| button[:id] == 'report-form-submit-btn' }
      disabled_table_button = disabled_buttons.find { |button| button[:id] == 'report-form-submit-btn' }
      enabled_auto_submitter = enabled_buttons.find { |button| button[:id] == 'report-form-auto-submitter-btn' }
      disabled_auto_submitter = disabled_buttons.find { |button| button[:id] == 'report-form-auto-submitter-btn' }

      expect(enabled_table_button[:classes]).to include('auto-submitter')
      expect(disabled_table_button[:classes]).not_to include('auto-submitter')
      expect(enabled_auto_submitter[:classes]).to include('hidden', 'auto-submitter')
      expect(disabled_auto_submitter[:classes]).to include('hidden', 'auto-submitter')
    end

    it 'hides only the table submission when hide_search_button is enabled' do
      report = create_report(
        report_type: 'search',
        view_options: { hide_search_button: true }
      )

      buttons = report_action_buttons(get_report_form(report))

      expect(buttons.map { |button| [button[:value], button[:classes].include?('hidden')] }).to eq [
        ['search', false], ['table', true]
      ]
    end

    it 'hides master-list search submissions when hide_master_results_list_search_button is enabled' do
      report = create_report(
        report_type: 'search', searchable: true,
        view_options: { hide_master_results_list_search_button: true }
      )

      page_buttons = report_action_buttons(get_report_form(report))
      panel_button = submit_buttons(get_report_form(report, part: 'form', view_context: 'search')).first

      expect(page_buttons.first[:classes]).to include('hidden')
      expect(page_buttons.last[:classes]).not_to include('hidden')
      expect(panel_button[:classes]).to include('hidden')
    end

    it 'omits count and export submissions when their legacy hide options are enabled' do
      report = create_report(
        report_type: 'regular_report',
        view_options: { hide_result_count: true, hide_export_buttons: true }
      )

      buttons = submit_buttons(get_report_form(report))

      expect(buttons.pluck(:value)).to eq ['table']
      expect(response.parsed_body.css('.search_count_reports')).to be_empty
    end

    it 'does not render count submission for count reports while retaining authorized exports' do
      report = create_report(report_type: 'count')

      buttons = submit_buttons(get_report_form(report))

      expect(buttons.pluck(:value)).to include('table', 'csv', 'json')
      expect(buttons.pluck(:value)).not_to include('count')
    end
  end

  describe 'legacy result submissions' do
    it 'returns master results for commit=search for every report type' do
      %w[regular_report search count].each do |report_type|
        report = create_report(report_type:)

        get "/reports/#{report.id}.json", params: { commit: 'search', search_attrs: { master_id: @master.id } }

        expect(response).to have_http_status(:ok), "#{report_type} response: #{response.body.first(500)}"
        expect(response.parsed_body.dig('masters', 0, 'id')).to eq(@master.id)
      end
    end

    it 'returns master results as JSON for the search_reports modal request path' do
      report = create_report(report_type: 'regular_report')

      get "/reports/#{report.id}.json", params: { commit: 'search', search_attrs: { master_id: @master.id } }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(response.body).to include(@master.id.to_s)
    end

    it 'renders a report table for commit=table and count-only results for commit=count' do
      report = create_report(report_type: 'regular_report')

      get report_path(report), params: { commit: 'table', part: 'results', search_attrs: { master_id: @master.id } }
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML.fragment(response.body).css('.report-results-table-block table.report-table')).not_to be_empty

      get report_path(report), params: { commit: 'count', part: 'results', search_attrs: { master_id: @master.id } }
      expect(response).to have_http_status(:ok)
      count_results = Nokogiri::HTML.fragment(response.body)
      expect(count_results.css('.report-results-block.hidden')).not_to be_empty
      expect(count_results.css('.count-only')).not_to be_empty
    end

    it 'renders embedded part=results without the report-page back and show buttons' do
      report = create_report(report_type: 'regular_report')

      get report_path(report), params: {
        commit: 'table', part: 'results', embed: 'true', search_attrs: { master_id: @master.id }
      }

      expect(response).to have_http_status(:ok)
      results = Nokogiri::HTML.fragment(response.body)
      expect(results.css('.report-results-table-block table.report-table')).not_to be_empty
      expect(results.css('.back-to-search-form-btn, .show-results-btn')).to be_empty
      expect(results.css('.report-results-block.no_results_scroll')).not_to be_empty
    end
  end

  private

  def create_report(report_type:, searchable: false, auto: false, view_options: {})
    search_attrs = <<~YAML
      master_id:
        number:
          all: true
          multiple: single
          disabled: false
    YAML
    report = Report.create!(
      current_admin: @admin,
      name: "Issue 1522 #{report_type} #{SecureRandom.hex(4)}",
      description: 'Legacy report button characterization',
      sql: 'select id as master_id from masters where id = :master_id',
      options: view_options.empty? ? nil : { 'view_options' => view_options.stringify_keys }.to_yaml,
      search_attrs:,
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
    report
  end

  def get_report_form(report, **params)
    get report_path(report), params: params
    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.css('#report_query_form')).not_to be_empty
    document
  end

  def submit_buttons(document)
    document.css('#report_query_form input[type="submit"], #report_query_form button[type="submit"]').map do |element|
      {
        label: element.name == 'button' ? element.text.strip : element['value'],
        name: element['name'],
        value: element['value'],
        classes: element['class'].to_s.split,
        id: element['id']
      }
    end
  end

  def report_action_buttons(document)
    submit_buttons(document).select { |button| %w[search table auto-submitter].include?(button[:value]) }
  end
end
