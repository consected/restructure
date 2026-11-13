# frozen_string_literal: true

# Defines the shared position/null/id ordering expected by all report lists.

require 'rails_helper'

RSpec.describe Report, type: :model do
  it 'orders reports by position with null positions last and id as the tie-breaker' do
    reports = [
      build_report(position: nil, auto: true, report_type: 'count'),
      build_report(position: 5, auto: true, report_type: 'report'),
      build_report(position: 1, auto: false, report_type: 'search'),
      build_report(position: 1, auto: false, report_type: 'regular_report')
    ]

    expect(described_class.ordered_for_display.where(id: reports.map(&:id)).pluck(:id)).to eq(
      [reports[2].id, reports[3].id, reports[1].id, reports[0].id]
    )
  end

  private

  def build_report(position:, auto:, report_type:)
    Report.create!(
      current_admin: Admin.first,
      name: "Issue 1522 ordering #{SecureRandom.hex(5)}",
      description: 'Report ordering characterization',
      sql: 'select 1 as value',
      search_attrs: '',
      disabled: false,
      report_type:,
      auto:,
      searchable: false,
      position:
    )
  end
end
