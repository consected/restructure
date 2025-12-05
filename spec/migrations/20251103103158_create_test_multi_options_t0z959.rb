require 'active_record/migration/app_generator'
class CreateTestMultiOptionsT0z959 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_multi_options'
    self.class_name = 'DynamicModel::TestMultiOptions'
    self.fields = %i[field_1 field_2 field_3 field_4 field_5 option_type alt_option_type]
    self.table_comment = 'Test from Specs'
    self.fields_comments = { field_1: nil, field_2: nil, field_3: nil, field_4: nil, field_5: nil, option_type: nil, alt_option_type: nil }
    self.db_configs =
      {
        'field_1' => { 'type' => 'string' },
        'field_2' => { 'type' => 'string' },
        'field_3' => { 'type' => 'string' },
        'field_4' => { 'type' => 'string' },
        'field_5' => { 'type' => 'string' },
        'option_type' => { 'type' => 'string' },
        'alt_option_type' => { 'type' => 'string' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
