# frozen_string_literal: true

# Tests for the get_query_count option in ReportOptions list_options.
# Issue #1011: User Reports page shows "loading..." splash for too long.
#
# The get_query_count option controls whether a report's record count
# is automatically fetched when the reports list page loads.
# Previously, all reports with auto: true would auto-run to get counts,
# causing delays. This option decouples count fetching from the auto flag.

require 'rails_helper'

RSpec.describe OptionConfigs::ReportOptions, type: :model do
  include ModelSupport
  include ReportSupport

  before :example do
    create_admin
    create_user
    create_reports
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
