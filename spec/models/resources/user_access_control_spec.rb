# frozen_string_literal: true

# Tests for Resources::UserAccessControl.resource_descriptions_for_activity_log_type.
#
# This method previously force-reset ActivityLog's option config caches
# (ActivityLog.reset_all_option_configs_resource_names! / reset_active_model_configurations!)
# on every single call, meaning every call to Admin::UserAccessControl.valid_resources
# (with no resource type filter, e.g. via #valid_user_access_controls) paid the cost of
# re-parsing option_configs for every active ActivityLog definition system-wide, even when
# nothing had changed since the previous call. These specs demonstrate that the caches are
# no longer force-reset on every read, while still being correctly invalidated when an
# ActivityLog definition is actually saved/regenerated.
#
# Also tests .resource_names_for_activity_log_type / Admin::UserAccessControl.resource_names_for(:activity_log_type),
# which now reads resource names from the already-maintained Resources::Models registry
# instead of parsing option_configs for every active ActivityLog at call time.

require 'rails_helper'

RSpec.describe Resources::UserAccessControl do
  describe '.resource_descriptions_for_activity_log_type' do
    before do
      # Start from a known, fully warm cache state for each example.
      ActivityLog.reset_all_option_configs_resource_names!
      ActivityLog.reset_active_model_configurations!
      described_class.resource_descriptions_for_activity_log_type
    end

    it 'does not force a reset of ActivityLog option config caches on a repeat call' do
      expect(ActivityLog).not_to receive(:reset_all_option_configs_resource_names!)
      expect(ActivityLog).not_to receive(:reset_active_model_configurations!)

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

    it 'does not force a reset of ActivityLog option config caches on a repeat call' do
      expect(ActivityLog).not_to receive(:reset_all_option_configs_resource_names!)
      expect(ActivityLog).not_to receive(:reset_active_model_configurations!)

      Admin::UserAccessControl.valid_resources
    end
  end

  describe '.resource_names_for_activity_log_type' do
    it 'returns the same set of resource names as the full labelled description' do
      full_parse_names = described_class.resource_descriptions_for_activity_log_type.values.flat_map(&:keys).map(&:to_s)

      expect(described_class.resource_names_for_activity_log_type.sort).to eq(full_parse_names.sort)
    end

    it 'does not parse option_configs (reads from the Resources::Models registry instead)' do
      expect_any_instance_of(ActivityLog).not_to receive(:option_configs)

      described_class.resource_names_for_activity_log_type
    end
  end

  describe 'Admin::UserAccessControl.resource_names_for(:activity_log_type)' do
    it 'delegates to the fast Resources::Models-backed path instead of the full description parse' do
      expect(described_class).to receive(:resource_names_for_activity_log_type).and_call_original
      expect(described_class).not_to receive(:resource_descriptions_for_activity_log_type)

      Admin::UserAccessControl.resource_names_for(:activity_log_type)
    end
  end
end
