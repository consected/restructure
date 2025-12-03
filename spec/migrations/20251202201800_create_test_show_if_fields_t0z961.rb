require 'active_record/migration/app_generator'
class CreateTestShowIfFieldsT0z961 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_show_if_fields'
    self.class_name = 'DynamicModel::TestShowIfFields'
    self.fields = %i[main_field_1 main_field_2 main_field_3 conditional_field_1 conditional_field_2 conditional_field_3]
    self.table_comment = 'Test show_if with embedded_item from Specs'
    self.fields_comments = { main_field_1: nil, main_field_2: nil, main_field_3: nil, conditional_field_1: nil, conditional_field_2: nil, conditional_field_3: nil }
    self.db_configs =
      {
        'main_field_1' => { 'type' => 'string' },
        'main_field_2' => { 'type' => 'string' },
        'main_field_3' => { 'type' => 'string' },
        'conditional_field_1' => { 'type' => 'string' },
        'conditional_field_2' => { 'type' => 'string' },
        'conditional_field_3' => { 'type' => 'string' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
