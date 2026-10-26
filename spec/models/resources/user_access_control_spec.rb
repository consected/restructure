# frozen_string_literal: true

# Tests that ActivityLog resource names are refreshed per validity check while reusing
# already-parsed definition_cache entries where their timestamps still match.

require 'rails_helper'

RSpec.describe Resources::UserAccessControl do
  describe '.resource_names_for(:activity_log_type)' do
    it 'returns the names represented by the full labelled descriptions' do
      names = Admin::UserAccessControl.resource_names_for(:activity_log_type)
      full_parse_names = described_class.resource_descriptions_for_activity_log_type.values.flat_map(&:keys).map(&:to_s)

      expect(names.sort).to eq(full_parse_names.sort)
    end
  end

  describe '.resource_descriptions_for_activity_log_type' do
    before do
      # Start from a known, fully warm cache state for each example.
      ActivityLog.reset_all_option_configs_resource_names!
      ActivityLog.reset_active_model_configurations!
      described_class.resource_descriptions_for_activity_log_type
    end

    it 'resets the resource-name and active-definition caches before rebuilding descriptions' do
      expect(ActivityLog).to receive(:reset_all_option_configs_resource_names!).and_call_original
      expect(ActivityLog).to receive(:reset_active_model_configurations!).and_call_original

      described_class.resource_descriptions_for_activity_log_type
    end

    it 'still returns the current grouped resources for active activity log definitions' do
      expect(described_class.resource_descriptions_for_activity_log_type)
        .to eq(ActivityLog.all_option_configs_grouped_resources)
    end
  end

  describe 'Admin::UserAccessControl.valid_resources (unfiltered, used by #valid_user_access_controls)' do
    before do
      ActivityLog.reset_all_option_configs_resource_names!
      ActivityLog.reset_active_model_configurations!
      Admin::UserAccessControl.valid_resources
    end

    it 'refreshes ActivityLog resource names during validation' do
      expect(ActivityLog).to receive(:reset_all_option_configs_resource_names!).and_call_original
      expect(ActivityLog).to receive(:reset_active_model_configurations!).and_call_original

      Admin::UserAccessControl.valid_resources
    end
  end
end

RSpec.describe ActivityLog, type: :model do
  it 'reuses a parsed definition_cache entry instead of re-parsing when rebuilding resource descriptions' do
    described_class.reset_active_model_configurations!
    id = described_class.active_model_configurations.first!.id
    previous = described_class.definition_cache[id]
    cached = described_class.find(id)
    cached.option_configs
    described_class.definition_cache[id] = cached
    allow(described_class.options_provider).to receive(:parse_config).and_call_original

    Resources::UserAccessControl.resource_descriptions_for_activity_log_type

    expect(described_class.options_provider)
      .not_to have_received(:parse_config).with(an_object_having_attributes(id:), anything)
  ensure
    if previous
      described_class.definition_cache[id] = previous
    elsif id
      described_class.definition_cache.delete(id)
    end
    described_class.reset_all_option_configs_resource_names!
    described_class.reset_active_model_configurations!
  end
end
