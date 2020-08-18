require 'active_record/migration/app_generator'
class CreateActivityLogPittBhiAssignmentPhoneScreensQeynno < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'pitt_bhi_assignment'
    self.schema = 'pitt_bhi'
    self.table_name = 'activity_log_pitt_bhi_assignment_phone_screens'
    self.fields = %i[]
    self.table_comment = ''
    self.fields_comments = {}


    create_activity_log_tables
    create_activity_log_trigger
  end
end
