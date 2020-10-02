require 'active_record/migration/app_generator'
class CreateRelatedSubjectQhis76 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'related_subjects'
    self.fields = %i[contact_master_id rec_type data first_name last_name select_relationship rank]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
