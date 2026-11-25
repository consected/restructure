# frozen_string_literal: true

# Characterizes the report type labels, persisted values, and type-specific predicates.

require 'rails_helper'

RSpec.describe Report, type: :model do
  describe 'report type metadata' do
    it 'provides ordered admin labels and stored values for all report types' do
      expected_report_types = [
        ['report', 'report'],
        ['count', 'count'],
        ['(deprecated) regular report', 'regular_report'],
        ['(deprecated) report and list records', 'search']
      ]

      expect(described_class::ReportTypes).to eq(expected_report_types)
      expect(described_class::ReportTypeValues).to eq(%w[report count regular_report search])
    end

    it 'provides the display label for a stored type' do
      report = described_class.new(report_type: 'regular_report')

      expect(report.report_type_label).to eq('(deprecated) regular report')
    end

    it 'identifies each stored report type with a predicate' do
      predicates = {
        report: :report_type_report?,
        count: :report_type_count?,
        regular_report: :report_type_regular_report?,
        search: :report_type_search?
      }

      predicates.each_key do |report_type|
        report = described_class.new(report_type:)

        predicates.each do |expected_type, predicate|
          expect(report.public_send(predicate)).to eq(expected_type == report_type)
        end
      end
    end
  end
end
