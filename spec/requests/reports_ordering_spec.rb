# frozen_string_literal: true

# Characterizes the reports index ordering independently of legacy auto/type grouping.

require 'rails_helper'

RSpec.describe 'Reports index ordering', type: :request do
  include ModelSupport

  before(:all) do
    SetupHelper.feature_setup
  end

  before do
    @admin, = create_admin
    @user, = create_user
    sign_in @user, scope: :user
    setup_access :view_reports, resource_type: :general, access: :read, user: @user
  end

  it 'orders accessible report rows by position nulls last and id ascending for ties' do
    reports = [
      create_report(position: nil, auto: true, report_type: 'count'),
      create_report(position: 5, auto: true, report_type: 'report'),
      create_report(position: 1, auto: false, report_type: 'search'),
      create_report(position: 1, auto: false, report_type: 'regular_report')
    ]

    get '/reports'

    expect(response).to have_http_status(:ok)
    expected_ids = [reports[2].id, reports[3].id, reports[1].id, reports[0].id]
    row_ids = response.parsed_body.css('tr[data-report-id]').map { |row| row['data-report-id'].to_i }
    expect(row_ids.select { |id| expected_ids.include?(id) }).to eq(expected_ids)
  end

  it 'shows report type labels and uses the regular-report glyph for the report type' do
    report = create_report(position: 1, auto: false, report_type: 'report')
    regular_report = create_report(position: 2, auto: false, report_type: 'regular_report')
    search_report = create_report(position: 3, auto: false, report_type: 'search')

    get '/reports'
    document = response.parsed_body

    [
      [report, 'report', 'glyphicon-list-alt'],
      [regular_report, '(deprecated) regular report', 'glyphicon-list-alt'],
      [search_report, '(deprecated) report and list records', 'glyphicon-search']
    ].each do |entry, label, glyph|
      row = document.at_css("tr[data-report-id='#{entry.id}']")
      expect(row.at_css('.report-index__type-cell .hidden').text).to eq(label)
      expect(row.at_css('.report-index__type-cell .glyphicon')['class']).to include(glyph)
    end
  end

  private

  def create_report(position:, auto:, report_type:)
    report = Report.create!(
      current_admin: @admin,
      name: "Issue 1522 ordered #{SecureRandom.hex(5)}",
      description: 'Report index ordering characterization',
      sql: 'select 1 as value',
      search_attrs: '',
      disabled: false,
      report_type:,
      auto:,
      searchable: false,
      position:
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
end
