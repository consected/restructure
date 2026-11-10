# frozen_string_literal: true

# Tests for issue #1263: Dynamic::DefHandler#active_model_configurations should not
# silently fall back to loading definitions from all app types when FPHS_LOAD_APP_TYPES
# (Settings::OnlyLoadAppTypes) is set to a value that matches no *active* app type
# (e.g. a typo'd id, or an app type that has since been disabled).
#
# - When the setting is present but unmatched, the result must be empty and a loud
#   error must be logged so the misconfiguration is obvious.
# - When the setting is absent (nil), definitions associated with all active app
#   types are loaded, while definitions associated only with disabled app types,
#   unassociated definitions, and disabled definitions are excluded.

require 'rails_helper'

RSpec.describe 'Dynamic::DefHandler#active_model_configurations fail-open handling', type: :model do
  include ModelSupport

  before do
    stub_const('Settings::OnlyLoadAppTypes', nil)
    create_admin

    @active_app_type_a = create_app_type(name: "active_model_configurations_a_#{SecureRandom.hex(4)}",
                                         label: 'Active model configurations A')
    @active_app_type_b = create_app_type(name: "active_model_configurations_b_#{SecureRandom.hex(4)}",
                                         label: 'Active model configurations B')
    @disabled_app_type = create_app_type(name: "active_model_configurations_disabled_#{SecureRandom.hex(4)}",
                                         label: 'Disabled model configurations')
    @disabled_app_type.update!(disabled: true, current_admin: @admin)

    @active_definition_a = create_dynamic_definition('a')
    @active_definition_b = create_dynamic_definition('b')
    @disabled_app_type_definition = create_dynamic_definition('disabled_app')
    @unassociated_definition = create_dynamic_definition('unassociated')
    @disabled_definition = create_dynamic_definition('disabled_definition', disabled: true)

    associate_dynamic_definition(@active_app_type_a, @active_definition_a)
    associate_dynamic_definition(@active_app_type_b, @active_definition_b)
    associate_dynamic_definition(@disabled_app_type, @disabled_app_type_definition)
    associate_dynamic_definition(@active_app_type_a, @disabled_definition, allow_bad_resource_name: true)

    reset_active_model_configuration_state
  end

  after do
    DynamicModel.reset_active_model_configurations!
    Admin::AppType.reset_memo_associated_items!
    Admin::AppType.reset_active_app_types!
  end

  def create_dynamic_definition(label, disabled: false)
    suffix = "x#{SecureRandom.hex(6)}"

    dynamic_definition = DynamicModel.create!(
      current_admin: @admin,
      name: "active model configurations #{label} #{suffix}",
      table_name: "active_model_configurations_#{label}_#{suffix}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      disabled: true
    )

    return dynamic_definition if disabled

    DynamicModel.where(id: dynamic_definition.id).update_all(disabled: false)
    dynamic_definition.reload
  end

  def associate_dynamic_definition(app_type, dynamic_definition, allow_bad_resource_name: false)
    Admin::UserAccessControl.create!(
      app_type:,
      resource_type: :table,
      resource_name: dynamic_definition.resource_name,
      access: :read,
      current_admin: @admin,
      allow_bad_resource_name:
    )
  end

  def reset_active_model_configuration_state
    Admin::AppType.reset_memo_associated_items!
    Admin::AppType.reset_active_app_types!
    DynamicModel.reset_active_model_configurations!
  end

  it 'loads definitions associated with all active app types when no setting is present' do
    result_ids = DynamicModel.active_model_configurations(force_update: true).pluck(:id)

    expect(result_ids).to include(@active_definition_a.id, @active_definition_b.id)
    expect(result_ids).not_to include(@disabled_app_type_definition.id,
                                      @unassociated_definition.id,
                                      @disabled_definition.id)
  end

  it 'returns an empty result and logs an error when FPHS_LOAD_APP_TYPES matches no active app type' do
    non_existent_app_type_id = (Admin::AppType.maximum(:id) || 0) + 999_999
    stub_const('Settings::OnlyLoadAppTypes', [non_existent_app_type_id])
    reset_active_model_configuration_state

    expect(Rails.logger).to receive(:error).with(/FPHS_LOAD_APP_TYPES.*matched no active app type/i)

    result = DynamicModel.active_model_configurations(force_update: true)

    expect(result.to_a).to be_empty
  end

  it 'returns an empty result when FPHS_LOAD_APP_TYPES names a disabled app type' do
    stub_const('Settings::OnlyLoadAppTypes', [@disabled_app_type.id])
    reset_active_model_configuration_state

    expect(Rails.logger).to receive(:error).with(/FPHS_LOAD_APP_TYPES.*matched no active app type/i)

    result = DynamicModel.active_model_configurations(force_update: true)

    expect(result.to_a).to be_empty
  end
end
