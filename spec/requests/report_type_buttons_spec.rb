# frozen_string_literal: true

# Covers the new report type's rendered button contexts, auto-submit classes,
# visibility options, and commit routes independently from legacy types.

require 'rails_helper'

RSpec.describe 'Report type report buttons', type: :request do
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

  it 'renders list-records, report, count, and export controls only in their intended contexts' do
    report = create_report(searchable: true)

    report_page = get_report_form(report)
    page_buttons = commit_buttons(report_page)
    expect(page_buttons.map { |button| [button[:label], button[:value]] }).to eq [
      ['report', 'table'], ['list records', 'search'], ['count', 'count']
    ]
    report_button = page_buttons.find { |button| button[:value] == 'table' }
    list_button = page_buttons.find { |button| button[:value] == 'search' }
    count_button = page_buttons.find { |button| button[:value] == 'count' }
    expect(report_button[:id]).to eq('report-form-submit-btn')
    expect(report_button[:classes]).to include('btn', 'btn-primary')
    expect(report_button[:classes]).not_to include('hidden', 'btn-default', 'btn-sm', 'pull-right', 'auto-run', 'auto-submitter')
    expect(list_button[:classes]).to include('hidden', 'btn', 'btn-primary')
    expect(count_button[:classes]).not_to include('hidden')
    expect(page_buttons.pluck(:id)).not_to include('report-form-auto-submitter-btn')
    expect(submit_buttons(report_page).pluck(:value)).to eq(%w[table search count csv json])
    expect(report_page.at_css('#report_query_form input[type="submit"][name="commit"][value="count"]')).not_to be_nil
    expect(report_page.css('#report_query_form button[type="submit"][value="count"]')).to be_empty
    expect(report_page.css('.search_count_reports')).not_to be_empty

    search_panel = get_report_form(report, part: 'form', view_context: 'search')
    panel_buttons = submit_buttons(search_panel)
    expect(panel_buttons.map { |button| [button[:label], button[:value]] }).to eq [['search', 'search']]
    expect(panel_buttons.first[:classes]).not_to include('hidden', 'auto-run', 'auto-submitter')
    inline_button = search_panel.at_css('.inline-search-button button[value="search"]')
    expect(inline_button).not_to be_nil
    expect(inline_button['class'].split).to include('btn', 'btn-default')
    expect(inline_button['class'].split).not_to include('btn-primary', 'btn-sm', 'pull-right')
    expect(search_panel.css('.search_count_reports')).not_to be_empty

    embedded = get_report_form(report, embed: 'true')
    embedded_buttons = commit_buttons(embedded)
    expect(embedded_buttons.map { |button| [button[:label], button[:value]] }).to eq [['report', 'table']]
    expect(embedded_buttons.first[:id]).to eq('report-form-submit-btn')
    expect(embedded_buttons.first[:classes]).to include('btn', 'btn-primary')
    expect(embedded_buttons.first[:classes]).not_to include('btn-default', 'btn-sm', 'pull-right')
    expect(submit_buttons(embedded).pluck(:value)).not_to include('count', 'csv', 'json', 'search')
    expect(embedded.css('.search_count_reports')).not_to be_empty
  end

  it 'applies report-page labels, visibility, independent count text, and auto-submit target options' do
    report = create_report(options: {
                             view_options: {
                               show_list_records_button: true,
                               list_records_button_label: 'View records',
                               report_button_label: 'Run report',
                               hide_count_button: true,
                               hide_result_count: true,
                               hide_export_buttons: true,
                               auto_submit_on_load: true,
                               auto_submit_on_change: true,
                               auto_submit_target: 'list_records'
                             }
                           })

    document = get_report_form(report)
    buttons = commit_buttons(document)
    list_button = buttons.find { |button| button[:value] == 'search' }
    report_button = buttons.find { |button| button[:value] == 'table' }
    count_button = buttons.find { |button| button[:value] == 'count' }

    expect([list_button[:label], list_button[:value]]).to eq ['View records', 'search']
    expect(list_button[:classes]).not_to include('hidden')
    expect(list_button[:classes]).to include('auto-run', 'auto-submitter')
    expect([report_button[:label], report_button[:value], report_button[:id]]).to eq [
      'Run report', 'table', 'report-form-submit-btn'
    ]
    expect(report_button[:classes]).not_to include('auto-run', 'auto-submitter', 'hidden')
    expect(count_button[:classes]).to include('hidden')
    expect(document.css('.search_count_reports')).to be_empty
    expect(submit_buttons(document).pluck(:value)).not_to include('csv', 'json')
    expect(document.css('#report-form-auto-submitter-btn')).to be_empty
  end

  it 'keeps count button visibility independent from the report count text' do
    hide_count_text = create_report(options: { view_options: { hide_result_count: true } })
    hidden_text_page = get_report_form(hide_count_text)
    visible_count_button = commit_buttons(hidden_text_page).find { |button| button[:value] == 'count' }
    expect(visible_count_button[:classes]).not_to include('hidden')
    expect(hidden_text_page.css('.search_count_reports')).to be_empty

    hide_count_button = create_report(options: { view_options: { hide_count_button: true } })
    hidden_button_page = get_report_form(hide_count_button)
    hidden_count_button = commit_buttons(hidden_button_page).find { |button| button[:value] == 'count' }
    expect(hidden_count_button[:classes]).to include('hidden')
    expect(hidden_button_page.css('.search_count_reports')).not_to be_empty
  end

  it 'keeps hidden auto-submit targets available in search-panel, report-page, and embedded contexts' do
    panel_report = create_report(searchable: true, options: {
                                   search_panel_options: {
                                     search_records_button_label: 'Find records',
                                     hide_search_records_button: true,
                                     auto_submit_on_load: true,
                                     auto_submit_on_change: true
                                   }
                                 })
    panel_button = submit_buttons(get_report_form(panel_report, part: 'form', view_context: 'search')).first
    expect([panel_button[:label], panel_button[:value]]).to eq ['Find records', 'search']
    expect(panel_button[:classes]).to include('hidden', 'auto-run', 'auto-submitter')

    embedded_report = create_report(options: {
                                      embedded_options: {
                                        report_button_label: 'Run in modal',
                                        hide_report_button: true,
                                        auto_submit_on_load: true,
                                        auto_submit_on_change: true
                                      }
                                    })
    embedded_button = commit_buttons(get_report_form(embedded_report, embed: 'true')).first
    expect([embedded_button[:label], embedded_button[:value]]).to eq ['Run in modal', 'table']
    expect(embedded_button[:classes]).to include('hidden', 'auto-run', 'auto-submitter')

    hidden_report_button = create_report(options: {
                                           view_options: {
                                             hide_report_button: true,
                                             auto_submit_on_load: true,
                                             auto_submit_on_change: true
                                           }
                                         })
    default_target_buttons = commit_buttons(get_report_form(hidden_report_button))
    expect(default_target_buttons.pluck(:value)).to eq(%w[table search count])
    expect(default_target_buttons.find { |button| button[:value] == 'search' }[:classes])
      .to include('hidden', 'auto-run', 'auto-submitter')
    expect(default_target_buttons.find { |button| button[:value] == 'table' }[:classes]).to include('hidden')

    overridden_target = create_report(options: {
                                        view_options: {
                                          hide_report_button: true,
                                          show_list_records_button: true,
                                          auto_submit_on_load: true,
                                          auto_submit_target: 'report'
                                        }
                                      })
    overridden_buttons = commit_buttons(get_report_form(overridden_target))
    expect(overridden_buttons.pluck(:value)).to eq(%w[search table count])
    expect(overridden_buttons.find { |button| button[:value] == 'table' }[:classes])
      .to include('hidden', 'auto-run')
    expect(overridden_buttons.find { |button| button[:value] == 'search' }[:classes]).not_to include('auto-run')
  end

  it 'forces auto-submit on load for the target in every context' do
    report = create_report(searchable: true)

    [
      [get_report_form(report, force_run: 'true'), 'table'],
      [get_report_form(report, part: 'form', view_context: 'search', force_run: 'true'), 'search'],
      [get_report_form(report, embed: 'true', force_run: 'true'), 'table']
    ].each do |document, target_value|
      target = commit_buttons(document).find { |button| button[:value] == target_value }
      expect(target[:classes]).to include('auto-run')
      expect(document.css('#report-form-auto-submitter-btn')).to be_empty
    end
  end

  it 'keeps the admin report criteria preview renderable for the new report type' do
    report = create_report
    sign_out :user
    sign_in @admin, scope: :admin

    get edit_admin_report_path(report)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('.admin-view.report-criteria')).not_to be_empty
    expect(response.body).not_to include('Failure in criteria view')
  end

  it 'returns master results, a table, and count-only results for commits regardless of button visibility' do
    report = create_report(
      sql: master_row_sql,
      options: { view_options: { hide_report_button: true, hide_count_button: true, hide_export_buttons: true } }
    )

    get report_path(report, format: :json), params: {
      commit: 'search', search_attrs: { master_id: @master.id }
    }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('masters', 0, 'id')).to eq(@master.id)

    get report_path(report), params: {
      commit: 'table', part: 'results', search_attrs: { master_id: @master.id }
    }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('.report-results-table-block table.report-table')).not_to be_empty

    get report_path(report), params: {
      commit: 'count', part: 'results', search_attrs: { master_id: @master.id }
    }
    expect(response).to have_http_status(:ok)
    count_results = response.parsed_body
    expect(count_results.css('.count-only')).not_to be_empty
    expect(count_results.css('.back-to-search-form-btn, .show-results-btn')).to be_empty
  end

  private

  def create_report(searchable: false, sql: nil, search_attrs: master_id_attrs, options: {})
    report = Report.create!(
      current_admin: @admin,
      name: "Issue 1522 report type buttons #{SecureRandom.hex(5)}",
      description: 'Report type button request coverage',
      sql: sql || master_row_sql,
      options: options.empty? ? nil : options.deep_stringify_keys.to_yaml,
      search_attrs:,
      disabled: false,
      report_type: 'report',
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

  def commit_buttons(document)
    submit_buttons(document).select { |button| button[:name] == 'commit' }
  end

  def master_row_sql
    "select id as master_id from masters where id = #{@master.id}"
  end

  def master_id_attrs
    <<~YAML
      master_id:
        number:
          all: true
          multiple: single
          disabled: false
    YAML
  end
end
