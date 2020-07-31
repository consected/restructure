require 'active_record/migration/app_generator'
class UpdateActivityLogDataRequestAssignmentsQec0tv < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'data_request_assignment'
    self.schema = 'data_requests'
    self.table_name = 'activity_log_data_request_assignments'
    self.fields = %i[created_by_user_id status notes next_step follow_up_date]
    self.table_comment = ''
    self.fields_comments = {}


    # added: []
    # removed: ["follow_up_time"]
    
    
    update_fields

    create_activity_log_trigger
  end
end
