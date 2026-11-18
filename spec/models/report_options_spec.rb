# frozen_string_literal: true

# Tests for the get_query_count option in ReportOptions list_options.
# Issue #1011: User Reports page shows "loading..." splash for too long.
#
# The get_query_count option controls whether a report's record count
# is automatically fetched when the reports list page loads. Unknown nested
# report options must remain editable and visible as configuration errors.
# Issue #1011: This option decouples count fetching from the legacy auto flag.

require 'rails_helper'

RSpec.describe OptionConfigs::ReportOptions, type: :model do
  include ModelSupport
  include ReportSupport

  before :example do
    create_admin
    create_user
    create_reports
  end

  describe 'unknown nested configuration parameters' do
    it 'loads all report option blocks, preserves valid values, and records each invalid key' do
      report = @report1
      report.options = {
        view_options: { hide_criteria_panel: true, bad_view_attr: 1 },
        search_panel_options: { auto_submit_on_change: true, bad_search_attr: 2 },
        embedded_options: { hide_report_button: true, bad_embedded_attr: 3 },
        list_options: { get_query_count: true, bad_list_attr: 4 }
      }.deep_stringify_keys.to_yaml

      options = nil
      expect { options = report.report_options }.not_to raise_error

      expect(options.view_options.hide_criteria_panel).to be(true)
      expect(options.search_panel_options.auto_submit_on_change).to be(true)
      expect(options.embedded_options.hide_report_button).to be(true)
      expect(options.list_options.get_query_count).to be(true)
      expect(options.config_errors).to contain_exactly(
        a_hash_including(
          config_class: described_class::ViewOptions.name,
          offending_keys: [:bad_view_attr],
          message: a_string_including('bad_view_attr')
        ),
        a_hash_including(
          config_class: described_class::SearchPanelOptions.name,
          offending_keys: [:bad_search_attr],
          message: a_string_including('bad_search_attr')
        ),
        a_hash_including(
          config_class: described_class::EmbeddedOptions.name,
          offending_keys: [:bad_embedded_attr],
          message: a_string_including('bad_embedded_attr')
        ),
        a_hash_including(
          config_class: described_class::ListOptions.name,
          offending_keys: [:bad_list_attr],
          message: a_string_including('bad_list_attr')
        )
      )
    end

    it 'allows an unknown option to be saved and corrected later' do
      report = @report1
      report.options = "view_options:\n  bad_attr: 1\n  hide_criteria_panel: true"

      expect { report.save! }.not_to raise_error
      expect(report.reload.report_options.config_errors.first[:offending_keys]).to eq([:bad_attr])

      report.options = "view_options:\n  hide_criteria_panel: true"
      expect { report.save! }.not_to raise_error
      expect(report.reload.report_options.config_errors).to be_empty
    end

    it 'still rejects invalid auto-submit values during report validation' do
      report = @report1
      report.options = "view_options:\n  auto_submit_on_load: invalid"

      expect(report.save).to be(false)
      expect(report.errors[:options].join).to include('auto_submit_on_load must be true, false or null')
    end
  end

  describe 'legacy result_handlers validation' do
    it 'allows array values and rejects non-arrays with the legacy save error' do
      report = @report1
      report.options = "view_options:\n  result_handlers: []"

      expect(report.save).to be(true)

      report.options = "view_options:\n  result_handlers: invalid"
      expect(report.save).to be(false)
      expect(report.errors[:options].map(&:message)).to include(
        'options view_options.result_handlers must be an array of handler names'
      )
    end
  end

  describe 'list_options.get_query_count' do
    it 'accepts get_query_count as a valid list_options configuration' do
      report = @report1
      report.current_admin = @admin
      report.options = "list_options:\n  get_query_count: true"
      report.save!

      ro = OptionConfigs::ReportOptions.new report
      expect(ro.list_options.get_query_count).to eq true
    end

    it 'returns nil/falsy when get_query_count is not set' do
      report = @report1
      report.current_admin = @admin
      report.options = ''
      report.save!

      ro = OptionConfigs::ReportOptions.new report
      expect(ro.list_options.get_query_count).to be_falsy
    end

    it 'returns false when get_query_count is explicitly set to false' do
      report = @report1
      report.current_admin = @admin
      report.options = "list_options:\n  get_query_count: false"
      report.save!

      ro = OptionConfigs::ReportOptions.new report
      expect(ro.list_options.get_query_count).to eq false
    end
  end
end
