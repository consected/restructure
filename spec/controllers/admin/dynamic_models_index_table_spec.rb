# frozen_string_literal: true

require 'rails_helper'

# Tests for the DynamicModelsController admin panel index table changes (issue #968):
# - Removed columns: schema_name, table_key_name, primary_key_name, foreign_key_name, result_order
# - Added extra index columns: resource_name, batch_jobs status, view? boolean
# - These new columns use the existing extra_index_columns mechanism
RSpec.describe Admin::DynamicModelsController, type: :controller do
  include ModelSupport
  include DynamicModelSupport

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

    it 'includes id, name, table_name, category, position, and admin_id' do
      required_columns = %i[id name table_name category position admin_id]
      result = controller.send(:index_params)
      required_columns.each do |col|
        expect(result).to include(col), "Expected index_params to include #{col}"
      end
    end
  end

  describe 'extra_index_columns' do
    it 'includes resource_name column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:resource_name_column)
      expect(result[:resource_name_column]).to eq('Resource name')
    end

    it 'includes batch_jobs column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:batch_jobs_column)
      expect(result[:batch_jobs_column]).to eq('Batch jobs')
    end

    it 'includes view? column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:view_sql_column)
      expect(result[:view_sql_column]).to eq('View?')
    end

    it 'still includes in_current_app_type column' do
      result = controller.send(:extra_index_columns)
      expect(result).to have_key(:in_current_app_type_result_checkbox)
      expect(result[:in_current_app_type_result_checkbox]).to eq('In current app type')
    end
  end

  describe 'resource_name_column' do
    it 'returns the resource name for a dynamic model' do
      dm = DynamicModel.active.first
      next unless dm

      result = controller.send(:resource_name_column, dm)
      expect(result).to eq(dm.resource_name)
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
end
