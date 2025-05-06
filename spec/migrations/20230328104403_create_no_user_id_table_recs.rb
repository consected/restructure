require 'active_record/migration/app_generator'
class CreateNoUserIdTableRecs < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'test'
    self.table_name = 'no_user_id_table_recs'
    self.class_name = 'DynamicModel::TestNoMasterDmAltIdRec'
    self.table_comment = 'Dynamicmodel: Test No Master Dm Rec Alt Id'
    self.fields = %i[data info alt_id]
    self.fields_comments = { data: 'Data', info: 'Information', alt_id: 'Alternative ID' }
    self.db_configs = { data: { type: 'string' }, info: { type: 'string' }, alt_id: { type: 'integer' } }
    self.no_master_association = true
    self.no_user_id = true
    self.resource_type = :dynamic_model
    self.all_referenced_tables = []
    create_dynamic_model_tables
  end
end
