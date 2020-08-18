require 'active_record/migration/app_generator'
class CreateActivityLogPittBhiAssignmentDiscussionsQf9hrz < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'pitt_bhi_assignment'
    self.schema = 'pitt_bhi'
    self.table_name = 'activity_log_pitt_bhi_assignment_discussions'
    self.fields = %i[notes tag_select_contact_role prev_activity_type]
    self.table_comment = ''
    self.fields_comments = {}


    create_activity_log_tables
    create_activity_log_trigger
  end
end
