require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentMedNavsQhxk3t < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignment_med_navs'
    self.fields = %i[activity_date select_direction select_contact select_result select_next_step follow_up_when follow_up_time select_activity notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = 


    self.prev_fields = %i[ipa_assignment_id select_activity activity_date select_contact select_direction select_result select_next_step follow_up_when follow_up_time notes]
    # added: []
    # removed: ["ipa_assignment_id"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
