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
#
# Additional tests for issue #1354 (index page slow to load with many dynamic models):
# - batch_jobs_column and view_sql_column now detect presence via a quick text scan of
#   the resolved options text (OptionConfigs::ExtraOptions.prepare_options_text), instead
#   of running the full option_configs parse for every row
# - batch_jobs_column now renders a boolean indicator, rather than the batch_trigger frequency
# - the scan is scoped to the _configurations: block only, so a field/label elsewhere in the
#   config happening to be named batch_trigger/view_sql is not treated as a false positive
#
# Additional follow-up UI tweaks:
# - "Batch jobs" column header renamed to "Batch job?"
# - Position column removed from index_params
# - Added an id filter dropdown
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
    it 'does not include schema_name, table_key_name, primary_key_name, foreign_key_name, result_order, or position' do
      removed_columns = %i[schema_name table_key_name primary_key_name foreign_key_name result_order position]
      result = controller.send(:index_params)
      removed_columns.each do |col|
        expect(result).not_to include(col), "Expected index_params not to include #{col}"
      end
    end

    it 'includes id, category, name, table_name, resource_name, and admin_id' do
      required_columns = %i[id category name table_name resource_name admin_id]
      result = controller.send(:index_params)
      required_columns.each do |col|
        expect(result).to include(col), "Expected index_params to include #{col}"
      end
    end
  end

  describe 'filters and filters_on' do
    it 'includes an id filter dropdown' do
      expect(controller.send(:filters_on)).to include(:id)
      expect(controller.send(:filters)).to have_key(:id)
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
      expect(result[:batch_jobs_column]).to eq('Batch job?')
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
    it 'returns unchecked when dynamic model has no batch_trigger configured' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test no batch trigger #{suffix}",
        table_name: "test_no_batch_trigger_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test"
      )

      result = controller.send(:batch_jobs_column, dm)
      expect(result).to include('val-unchecked')
    end

    it 'returns checked when batch_trigger is configured' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test batch trigger #{suffix}",
        table_name: "test_batch_trigger_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "_configurations:\n  batch_trigger:\n    frequency: 1 hour\ndefault:\n  label: Test"
      )

      result = controller.send(:batch_jobs_column, dm)
      expect(result).to include('val-checked')
    end

    it 'returns unchecked without running the full option_configs parse (issue #1354)' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test no full parse #{suffix}",
        table_name: "test_no_full_parse_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test"
      )

      expect(dm).not_to receive(:option_configs)
      controller.send(:batch_jobs_column, dm)
    end

    it 'returns unchecked when "batch_trigger" only appears as a field/label name, not a real _configurations key' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test false positive batch trigger #{suffix}",
        table_name: "test_fp_batch_trigger_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test\n  fields:\n    - batch_trigger\n  labels:\n    batch_trigger: \"Not a real trigger\"\n"
      )

      result = controller.send(:batch_jobs_column, dm)
      expect(result).to include('val-unchecked')
    end
  end

  describe 'view_sql_column' do
    it 'returns unchecked when dynamic model has no view_sql configured' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test no view sql #{suffix}",
        table_name: "test_no_view_sql_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test"
      )

      result = controller.send(:view_sql_column, dm)
      # Should render an unchecked boolean field
      expect(result).to include('val-unchecked')
    end

    it 'returns checked when dynamic model has view_sql configured' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test view sql #{suffix}",
        table_name: "test_view_sql_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "_configurations:\n  view_sql: |\n    select id, master_id from player_infos\n"
      )

      result = controller.send(:view_sql_column, dm)
      # Should render a checked boolean field
      expect(result).to include('val-checked')
    end

    it 'returns unchecked when "view_sql" only appears as a field/label name, not a real _configurations key' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join
      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test false positive view sql #{suffix}",
        table_name: "test_fp_view_sql_#{suffix}_recs",
        schema_name: 'dynamic_test',
        category: 'test',
        disabled: true,
        options: "default:\n  label: Test\n  fields:\n    - view_sql\n  labels:\n    view_sql: \"Not a real view_sql config\"\n"
      )

      result = controller.send(:view_sql_column, dm)
      expect(result).to include('val-unchecked')
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
