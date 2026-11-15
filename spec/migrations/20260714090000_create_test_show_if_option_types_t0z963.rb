# frozen_string_literal: true

require 'active_record/migration/app_generator'
class CreateTestShowIfOptionTypesT0z963 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_show_if_option_types'
    self.class_name = 'DynamicModel::TestShowIfOptionTypes'
    self.fields = %i[instrument_type event_type visit_name form_label flag_field]
    self.table_comment = 'Test show_if in show mode with option types from Specs (issue #1254)'
    self.fields_comments = { instrument_type: nil, event_type: nil, visit_name: nil, form_label: nil, flag_field: nil }
    self.db_configs =
      {
        'instrument_type' => { 'type' => 'string' },
        'event_type' => { 'type' => 'string' },
        'visit_name' => { 'type' => 'string' },
        'form_label' => { 'type' => 'string' },
        'flag_field' => { 'type' => 'boolean' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
