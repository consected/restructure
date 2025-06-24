require 'active_record/migration/app_generator'
class CreateTestLongitudinalFieldsRecsSyb0kw < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
        self.schema = 'test'
    self.table_name = 'test_longitudinal_fields_recs'
    self.class_name = 'DynamicModel::TestLongitudinalFieldsRec'
    self.fields = %i[record_id text1 study_id research_form_complete test_name email visit_form_complete redcap_event_name]
    self.table_comment = "Dynamicmodel: Longitudinal"
    self.fields_comments = {record_id: "Record ID", text1: "text1", study_id: "Study ID", test_name: nil, email: nil}
    self.db_configs = {record_id: {type: "string"}, text1: {type: "string"}, study_id: {type: "integer"}, research_form_complete: {type: "integer"}, test_name: {type: "string"}, email: {type: "string"}, visit_form_complete: {type: "integer"}, redcap_event_name: {type: "string"}}
    self.no_master_association = true
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []



    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
