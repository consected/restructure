# frozen_string_literal: true

# Specs for TrackerHistoryFilterConfig - configuration parsing and regex-driven
# initial preselection logic for the tracker history panel filters
# (consected/restructure issue #1074).
#
# Covers:
# - Loading a YAML hash from the `tracker history initial filters` app config
# - Compiling string regexes safely with exception handling
# - Matching options by name (not ID), supporting inclusion and exclusion patterns
# - Graceful degradation and warning on invalid regexes

require 'rails_helper'

RSpec.describe TrackerHistoryFilterConfig, type: :model do
  include ModelSupport
  include ActiveSupport::Testing::TimeHelpers

  before(:each) do
    create_user
    create_admin
    Admin::AppConfiguration.clear_memo!
  end

  describe '.config_for' do
    it 'returns a hash with regex source strings keyed by filter group when configured' do
      yaml = <<~YAML
        protocols: '^Study'
        sub_processes: 'consented'
        protocol_events: 'visit_[0-9]+'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      config = described_class.config_for(@user)

      expect(config).to include(
        protocols: '^Study',
        sub_processes: 'consented',
        protocol_events: 'visit_[0-9]+'
      )
    end

    it 'returns an empty hash when no config is set' do
      expect(described_class.config_for(@user)).to eq({})
    end

    it 'ignores unknown keys but keeps known ones' do
      yaml = <<~YAML
        protocols: 'Study'
        bogus_key: 'ignored'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      config = described_class.config_for(@user)
      expect(config.keys).to contain_exactly(:protocols)
    end

    it 'does not return the notes literal value (it is not a regex group)' do
      yaml = <<~YAML
        protocols: 'Study'
        notes: 'follow-up'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      expect(described_class.config_for(@user).keys).to contain_exactly(:protocols)
    end
  end

  describe '.notes_initial_for' do
    it 'returns the configured notes literal string' do
      yaml = <<~YAML
        notes: 'follow-up'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      expect(described_class.notes_initial_for(@user)).to eq('follow-up')
    end

    it 'returns an empty string when not configured' do
      expect(described_class.notes_initial_for(@user)).to eq('')
    end

    it 'preserves the literal value verbatim (no regex interpretation)' do
      yaml = <<~YAML
        notes: '[hello].*'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      expect(described_class.notes_initial_for(@user)).to eq('[hello].*')
    end
  end

  describe '.date_initial_for' do
    it 'returns YYYY-MM-DD strings for absolute date_from / date_to literals' do
      yaml = <<~YAML
        date_from: '2025-02-01'
        date_to: '2025-03-31'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      expect(described_class.date_initial_for(@user)).to eq(
        date_from: '2025-02-01',
        date_to: '2025-03-31'
      )
    end

    it 'resolves relative duration strings such as "-10 days" via FieldDefaults' do
      yaml = <<~YAML
        date_from: '-10 days'
        date_to: 'today()'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      travel_to(Time.zone.local(2025, 6, 15, 10, 0, 0)) do
        expect(described_class.date_initial_for(@user)).to eq(
          date_from: '2025-06-05',
          date_to: '2025-06-15'
        )
      end
    end

    it 'returns an empty hash when no date config is set' do
      expect(described_class.date_initial_for(@user)).to eq({})
    end

    it 'omits keys with blank or unparseable values' do
      yaml = <<~YAML
        date_from: ''
        date_to: 'not-a-date'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      expect(described_class.date_initial_for(@user)).to eq({})
    end
  end

  describe '.match_names' do
    let(:names) { ['Study Visit 1', 'Study Visit 2', 'Recruitment', 'Withdrawn'] }

    it 'returns names matching an inclusion regex' do
      expect(described_class.match_names('^Study', names)).to eq(['Study Visit 1', 'Study Visit 2'])
    end

    it 'supports exclusion via negative lookahead' do
      expect(described_class.match_names('^(?!Study).+', names)).to eq(['Recruitment', 'Withdrawn'])
    end

    it 'returns an empty array when no names match' do
      expect(described_class.match_names('Nope', names)).to eq([])
    end

    it 'returns an empty array and logs a warning for an invalid regex' do
      expect(Rails.logger).to receive(:warn).with(/tracker history initial filters/i)
      expect(described_class.match_names('[invalid', names)).to eq([])
    end

    it 'returns an empty array for blank pattern' do
      expect(described_class.match_names('', names)).to eq([])
      expect(described_class.match_names(nil, names)).to eq([])
    end
  end

  describe '.initial_selections' do
    let(:options) do
      {
        protocols: ['Study A', 'Study B', 'Other'],
        sub_processes: ['consented', 'declined'],
        protocol_events: ['visit_1', 'visit_2', 'phone']
      }
    end

    it 'returns matched names for each configured group, leaving others empty' do
      yaml = <<~YAML
        protocols: '^Study'
        protocol_events: '^visit_'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      result = described_class.initial_selections(options, @user)

      expect(result).to eq(
        protocols: ['Study A', 'Study B'],
        sub_processes: [],
        protocol_events: ['visit_1', 'visit_2']
      )
    end

    it 'does not raise and falls back to empty selection on invalid regex' do
      yaml = <<~YAML
        protocols: '[bad'
        sub_processes: 'consented'
      YAML
      Admin::AppConfiguration.add_default_config(@user.app_type, :tracker_history_initial_filters, yaml, @admin)

      allow(Rails.logger).to receive(:warn)

      result = described_class.initial_selections(options, @user)
      expect(result[:protocols]).to eq([])
      expect(result[:sub_processes]).to eq(['consented'])
      expect(result[:protocol_events]).to eq([])
    end
  end
end
