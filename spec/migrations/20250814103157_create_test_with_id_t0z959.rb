require 'active_record/migration/app_generator'
class CreateTestWithIdT0z959 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_with_id_recs'
    self.class_name = 'DynamicModel::TestWithIdRec'
    self.fields = %i[value name]
    self.table_comment = 'Test from Specs'
    self.fields_comments = { value: nil, name: nil }
    self.db_configs =
      {
        'value' => { 'type' => 'string' },
        'name' => { 'type' => 'string' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
