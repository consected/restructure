require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentNavigationsQhxk3r < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignment_navigations'
    self.fields = %i[select_event_type other_event_type select_station location event_date start_time completion_time select_status select_navigator select_pi other_navigator_notes arrival_time event_notes participant_feedback_notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = 


    self.prev_fields = %i[ipa_assignment_id event_date select_station arrival_time start_time event_notes completion_time participant_feedback_notes other_navigator_notes select_event_type other_event_type select_status select_navigator select_pi location]
    # added: []
    # removed: ["ipa_assignment_id"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
