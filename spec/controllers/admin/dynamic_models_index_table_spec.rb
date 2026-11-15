# frozen_string_literal: true

require 'rails_helper'

# Tests for the DynamicModelsController admin panel index table changes (issue #968):
# - Removed columns: schema_name, table_key_name, primary_key_name, foreign_key_name, result_order
# - Added resource_name to index_params as a regular column
# - Added extra index columns: batch_jobs status, "Is a view?" boolean
# - These new columns use the existing extra_index_columns mechanism
#
# Additional tests for issue #1066:
# - Show resolved definition versioning in definition details
# - Show the edited record id in the Edit Entry title
RSpec.describe Admin::DynamicModelsController, type: :controller do
  include ModelSupport
  include DynamicModelSupport

  render_views

  before :all do
    create_admin
    create_user
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    sign_in @admin
  end

  describe 'index_params' do
    it 'does not include schema_name, table_key_name, primary_key_name, foreign_key_name, or result_order' do
      removed_columns = %i[schema_name table_key_name primary_key_name foreign_key_name result_order]
      result = controller.send(:index_params)
      removed_columns.each do |col|
        expect(result).not_to include(col), "Expected index_params not to include #{col}"
      end
    end

    it 'includes id, category, name, table_name, resource_name, position, and admin_id' do
      required_columns = %i[id category name table_name resource_name position admin_id]
      result = controller.send(:index_params)
      required_columns.each do |col|
        expect(result).to include(col), "Expected index_params to include #{col}"
      end
    end
  end

  describe 'extra_index_columns' do
    it 'does not include resource_name (it is a regular index_params column)' do
      result = controller.send(:extra_index_columns)
      expect(result.keys.map(&:to_s)).not_to include('resource_name_column')
    end

    it 'includes batch_jobs column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:batch_jobs_column)
      expect(result[:batch_jobs_column]).to eq('Batch jobs')
    end

    it 'includes "Is a view?" column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:view_sql_column)
      expect(result[:view_sql_column]).to eq('Is a view?')
    end

    it 'still includes in_current_app_type column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:in_current_app_type_result_checkbox)
      expect(result[:in_current_app_type_result_checkbox]).to eq('In current app type')
    end
  end

  describe 'batch_jobs_column' do
    it 'returns empty string when dynamic model has no batch_trigger configured' do
      dm = DynamicModel.active.first
      next unless dm

      # Ensure no batch_trigger is configured
      allow(dm).to receive(:configurations).and_return(nil)
      result = controller.send(:batch_jobs_column, dm)
      expect(result).to eq('')
    end

    it 'returns a status indicator when batch_trigger is configured' do
      dm = DynamicModel.active.first
      next unless dm

      allow(dm).to receive(:configurations).and_return({ batch_trigger: { frequency: '1 hour' } })
      result = controller.send(:batch_jobs_column, dm)
      expect(result).to be_present
    end
  end

  describe 'view_sql_column' do
    it 'returns unchecked when dynamic model has no view_sql configured' do
      dm = DynamicModel.active.first
      next unless dm

      allow(dm).to receive(:configurations).and_return(nil)
      result = controller.send(:view_sql_column, dm)
      # Should render an unchecked boolean field
      expect(result).to include('val-unchecked')
    end

    it 'returns checked when dynamic model has view_sql configured' do
      dm = DynamicModel.active.first
      next unless dm

      allow(dm).to receive(:configurations).and_return({ view_sql: 'SELECT 1' })
      result = controller.send(:view_sql_column, dm)
      # Should render a checked boolean field
      expect(result).to include('val-checked')
    end
  end

  describe 'GET #edit issue #1066 details display' do
    it 'shows current version when current-definition mode is resolved and includes record id in the title' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test version mode #{suffix}",
        table_name: "test_version_mode_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "_configurations:\n  use_current_version: true\ndefault:\n  label: Test"
      )

      allow_any_instance_of(DynamicModel).to receive(:uses_current_definition_version?).and_return(true)

      get :edit, params: { id: dm.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /current version/i)
      expect(response.body).to include("Edit Entry <small>##{dm.id}</small>")
    end

    it 'shows complete default versioning help text for definition-at-record-creation mode issue #1094' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test default version help #{suffix}",
        table_name: "test_default_version_help_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test"
      )

      allow_any_instance_of(DynamicModel).to receive(:versioning_disabled_globally?).and_return(false)
      allow_any_instance_of(DynamicModel).to receive(:definition_uses_current_version_option?).and_return(false)

      get :edit, params: { id: dm.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Resolved from the default definition-at-record-creation versioning behavior.')
    end

    it 'renders the use_current_version option as a code element when config_ucv resolves it issue #1094' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test config ucv mode #{suffix}",
        table_name: "test_config_ucv_mode_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "_configurations:\n  use_current_version: true\ndefault:\n  label: Test"
      )

      allow_any_instance_of(DynamicModel).to receive(:versioning_disabled_globally?).and_return(false)
      allow_any_instance_of(DynamicModel).to receive(:definition_uses_current_version_option?).and_return(true)
      allow_any_instance_of(DynamicModel).to receive(:uses_current_definition_version?).and_return(true)

      get :edit, params: { id: dm.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('p.help-block code', text: '_configurations.use_current_version')
      expect(response.body).to include('Resolved from')
    end

    it 'shows that definition-time versioning is used when current-version mode is not enabled' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test versioned mode #{suffix}",
        table_name: "test_versioned_mode_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test"
      )

      get :edit, params: { id: dm.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /record creation/i)
    end
  end
end
