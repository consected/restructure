# frozen_string_literal: true

# ReportResults::ReportsTableHelper Spec - Issue #1000
#
# Tests that report_table_header_cache_key produces different cache keys
# when the editable? state differs (e.g., embedded vs non-embedded context).
#
# The bug: the cache key does not include whether the report is editable
# in the current context. When a user views a report with edit_model configured
# (non-embedded), the header is cached WITH an extra <th> for the edit button.
# When the admin preview renders the same report (@embedded_report=true),
# editable? returns nil, but the same cache key is used, so the stale header
# with the extra <th> is served. Data rows don't have the extra <td>, causing
# all column headers to be shifted by one position.
#
# Test Coverage:
# - report_table_header_cache_key returns different keys for editable vs non-editable contexts
# - This test FAILS against the current code because editable? is not part of the cache key

require 'rails_helper'

RSpec.describe ReportResults::ReportsTableHelper, type: :helper do
  include ModelSupport

  before(:all) do
    create_admin
    create_user

    @report = Report.create!(
      current_admin: @admin,
      name: "Cache Key Test #{SecureRandom.hex(4)}",
      description: 'Test report for cache key editable state',
      sql: 'select * from player_infos limit 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false,
      position: nil,
      edit_model: 'player_infos',
      edit_field_names: 'first_name,last_name'
    )
  end

  after(:all) do
    @report&.update(disabled: true, current_admin: @admin) if @report&.persisted?
  end

  describe '#report_table_header_cache_key' do
    let(:data_reference) do
      double('DataReference', schema_name: 'ml_app', table_name: 'player_infos')
    end

    let(:runner) do
      double('Runner', data_reference: data_reference)
    end

    before do
      # Set up the instance variables the helper expects
      helper.instance_variable_set(:@report, @report)
      helper.instance_variable_set(:@runner, runner)

      # Stub current_user/current_admin so partial_cache_key works
      helper.define_singleton_method(:current_user) { @user }
      helper.define_singleton_method(:current_admin) { nil }
      helper.instance_variable_set(:@user, @user)
    end

    it 'produces different cache keys when editable? returns different values' do
      # Non-embedded context: editable? returns true (edit_model is set, admin/user has access)
      helper.instance_variable_set(:@embedded_report, nil)
      helper.define_singleton_method(:current_admin) { @admin }
      helper.instance_variable_set(:@admin, @admin)
      non_embedded_key = helper.report_table_header_cache_key

      # Reset memoized state that partial_cache_key may have cached
      helper.instance_variable_set(:@item_updates, nil)

      # Embedded context: editable? returns nil (short-circuits because @embedded_report is set)
      helper.instance_variable_set(:@embedded_report, true)
      embedded_key = helper.report_table_header_cache_key

      # These should be DIFFERENT because the header content differs based on editable? state.
      # This assertion FAILS with the current code because the cache key does not include
      # the editable? state — both contexts produce the same key, causing stale headers.
      expect(non_embedded_key).not_to eq(embedded_key),
        'Cache keys should differ between embedded (non-editable) and non-embedded (editable) contexts, ' \
        "but both produced: #{non_embedded_key}"
    end
  end
end
