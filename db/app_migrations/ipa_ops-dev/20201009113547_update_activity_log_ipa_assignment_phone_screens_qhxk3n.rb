require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentPhoneScreensQhxk3n < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignment_phone_screens'
    self.fields = %i[callback_required callback_date callback_time notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = 


    self.prev_fields = %i[ipa_assignment_id callback_date callback_time notes callback_required]
    # added: []
    # removed: ["ipa_assignment_id"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
