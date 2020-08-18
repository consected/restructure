require 'active_record/migration/app_generator'
class UpdateFemflSubjectsQf0dls < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'femfl_subjects'
    self.fields = %i[first_name last_name middle_name nick_name birth_date source tracker_history_id rank]
    self.table_comment = ''
    self.fields_comments = {}


    # added: ["tracker_history_id", "rank"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
