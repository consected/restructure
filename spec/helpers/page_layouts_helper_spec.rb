# frozen_string_literal: true

require 'rails_helper'

# Unit tests for PageLayoutsHelper methods, specifically the format_active_values
# helper used for configuring sublist filter button defaults.
# Related to GitHub Issue #584.

RSpec.describe PageLayoutsHelper, type: :helper do
  describe '#format_active_values' do
    it 'returns empty string for nil values' do
      expect(helper.format_active_values(nil)).to eq('')
    end

    it "returns 'all' when value is 'all' string" do
      expect(helper.format_active_values('all')).to eq('all')
    end

    it "returns 'none' for empty array" do
      expect(helper.format_active_values([])).to eq('none')
    end

    it 'returns comma-separated string for array of integers' do
      expect(helper.format_active_values([10, 5, -1])).to eq('10,5,-1')
    end

    it 'returns comma-separated string for array of strings' do
      expect(helper.format_active_values(%w[primary secondary])).to eq('primary,secondary')
    end

    it 'returns comma-separated string for mixed array' do
      expect(helper.format_active_values([10, 'active', 5])).to eq('10,active,5')
    end

    it 'returns string representation for single value' do
      expect(helper.format_active_values(10)).to eq('10')
    end

    it 'converts symbols to strings' do
      expect(helper.format_active_values(:active)).to eq('active')
    end
  end
end
