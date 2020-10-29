require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentDiscussionsQhxk3w < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignment_discussions'
    self.fields = %i[notes tag_select_contact_role prev_activity_type created_by_user_id]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = 


    self.prev_fields = %i[ipa_assignment_id tag_select_contact_role notes prev_activity_type created_by_user_id]
    # added: []
    # removed: ["ipa_assignment_id"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
