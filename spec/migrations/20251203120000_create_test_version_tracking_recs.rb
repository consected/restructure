require 'active_record/migration/app_generator'
class CreateTestVersionTrackingRecs < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic_test'
    self.table_name = 'test_version_tracking_recs'
    self.class_name = 'DynamicTest::TestVersionTrackingRecs'
    self.fields = %i[test_field]
    self.table_comment = 'Test version tracking from admin_dynamic_model_versions_spec'
    self.fields_comments = { test_field: nil }
    self.db_configs =
      {
        'test_field' => { 'type' => 'string' }
      }.deep_symbolize_keys
    self.no_master_association = false
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
