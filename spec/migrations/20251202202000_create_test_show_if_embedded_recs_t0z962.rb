require 'active_record/migration/app_generator'
class CreateTestShowIfEmbeddedRecsT0z962 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_show_if_embedded_recs'
    self.class_name = 'DynamicModel::TestShowIfEmbeddedRecs'
    self.fields = %i[embedded_status embedded_score test_show_if_field_id]
    self.table_comment = 'Test show_if embedded items from Specs'
    self.fields_comments = { embedded_status: nil, embedded_score: nil, test_show_if_field_id: nil }
    self.db_configs =
      {
        'embedded_status' => { 'type' => 'string' },
        'embedded_score' => { 'type' => 'integer' },
        'test_show_if_field_id' => { 'type' => 'integer' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
