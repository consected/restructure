require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentAdverseEventsQhxk3s < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignment_adverse_events'
    self.fields = %i[select_who done_when notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = 


    self.prev_fields = %i[ipa_assignment_id select_who done_when notes]
    # added: []
    # removed: ["ipa_assignment_id"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
