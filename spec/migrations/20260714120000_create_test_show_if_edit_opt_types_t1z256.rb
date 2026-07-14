# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateTestShowIfEditOptTypesT1z256 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_show_if_edit_opt_types'
    self.class_name = 'DynamicModel::TestShowIfEditOptTypes'
    self.fields = %i[instrument_type trigger_field cond_field]
    self.table_comment = 'Test show_if in edit mode with divergent option type rules (issue #1256)'
    self.fields_comments = { instrument_type: nil, trigger_field: nil, cond_field: nil }
    self.db_configs =
      {
        'instrument_type' => { 'type' => 'string' },
        'trigger_field' => { 'type' => 'string' },
        'cond_field' => { 'type' => 'string' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
