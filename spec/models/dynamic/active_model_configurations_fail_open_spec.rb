# frozen_string_literal: true

# Tests for issue #1263: Dynamic::DefHandler#active_model_configurations should not
# silently fall back to loading ALL active definitions when FPHS_LOAD_APP_TYPES
# (Settings::OnlyLoadAppTypes) is set to a value that matches no *active* app type
# (e.g. a typo'd id, or an app type that has since been disabled).
#
# - When the setting is present but unmatched, the result must be empty (not all
#   active definitions), and a loud error must be logged so the misconfiguration
#   is obvious.
# - When the setting is absent (nil), the existing bootstrap behaviour of loading
#   all active definitions must be preserved.

require 'rails_helper'

RSpec.describe 'Dynamic::DefHandler#active_model_configurations fail-open handling', type: :model do
  include ModelSupport

  before do
    DynamicModel.reset_active_model_configurations!
  end

  after do
    DynamicModel.reset_active_model_configurations!
  end

  it 'returns all active definitions when no FPHS_LOAD_APP_TYPES setting is present (bootstrap path)' do
    stub_const('Settings::OnlyLoadAppTypes', nil)

    result = DynamicModel.active_model_configurations(force_update: true)

    expect(result.to_a.map(&:id)).to match_array DynamicModel.active.map(&:id)
  end

  it 'returns an empty result and logs an error when FPHS_LOAD_APP_TYPES matches no active app type' do
    all_active_ids = DynamicModel.active.map(&:id)
    expect(all_active_ids).not_to be_empty, 'expected at least one active DynamicModel definition to exist in test seed data'

    non_existent_app_type_id = (Admin::AppType.maximum(:id) || 0) + 999_999
    stub_const('Settings::OnlyLoadAppTypes', [non_existent_app_type_id])

    expect(Rails.logger).to receive(:error).with(/FPHS_LOAD_APP_TYPES.*matched no active app type/i)

    result = DynamicModel.active_model_configurations(force_update: true)

    expect(result.to_a).to be_empty
  end
end
