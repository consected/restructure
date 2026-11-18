# frozen_string_literal: true

# Admin::ReportsController Spec (issue #63)
#
# Tests the search_attr_definer cache headers and legacy report option save round-trips.

require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do
  include MasterSupport

  before_each_login_admin

  describe 'legacy report admin round-trip' do
    render_views

    it 'keeps auto and legacy options when saving a legacy report and renders the labelled type choices' do
      options_text = legacy_options_text
      report = create_controller_report(report_type: 'regular_report', auto: true, options: options_text)

      get :edit, params: { id: report.id }

      expect(response).to have_http_status(:ok)
      type_select = Nokogiri::HTML.fragment(response.body).at_css('#report_report_type')
      expect(type_select).not_to be_nil
      expect(type_select.css('option').map { |option| [option.text.strip, option['value']] }).to include(
        ['report', 'report'],
        ['count', 'count'],
        ['(deprecated) regular report', 'regular_report'],
        ['(deprecated) report and list records', 'search']
      )

      put :update, params: {
        id: report.id,
        report: { report_type: 'regular_report', auto: '1', options: options_text }
      }

      expect(report.reload.report_type).to eq('regular_report')
      expect(report.auto).to be(true)
      expect(report.options).to eq(options_text)
    end

    it 'retains a previously stored auto value when changing the new report type back to legacy' do
      report = create_controller_report(report_type: 'report', auto: true, options: legacy_options_text)

      put :update, params: { id: report.id, report: { report_type: 'regular_report' } }

      expect(report.reload.report_type).to eq('regular_report')
      expect(report.auto).to be(true)
    end

    def create_controller_report(report_type:, auto:, options:)
      Report.create!(
        current_admin: @admin,
        name: "Issue 1522 admin round-trip #{SecureRandom.hex(4)}",
        description: 'Legacy report admin round-trip coverage',
        sql: 'select 1 as result_value',
        search_attrs: '',
        options:,
        report_type:,
        auto:,
        disabled: false
      )
    end

    def legacy_options_text
      <<~YAML
        view_options:
          hide_search_button: true
          report_auto_submit_on_change: true
          no_results_scroll: true
          prevent_collapse_for_list: true
        list_options:
          hide_in_list: true
      YAML
    end
  end

  describe '#search_attr_definer (issue #63)' do
    it 'sets Cache-Control with private and max-age' do
      get :search_attr_definer

      cache_control = response.headers['Cache-Control']
      expect(cache_control).to include('private')
      expect(cache_control).to include("max-age=#{48.hours.to_i}")
      expect(cache_control).not_to include('immutable')
    end
  end
end
