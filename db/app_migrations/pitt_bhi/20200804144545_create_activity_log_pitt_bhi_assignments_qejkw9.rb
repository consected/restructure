require 'active_record/migration/app_generator'
class CreateActivityLogPittBhiAssignmentsQejkw9 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'pitt_bhi_assignment'
    self.schema = 'pitt_bhi'
    self.table_name = 'activity_log_pitt_bhi_assignments'
    self.fields = %i[select_who select_record_from_player_contacts follow_up_when follow_up_time notes activity_date select_activity select_record_from_addresses select_direction select_result select_next_step]
    self.table_comment = ''
    self.fields_comments = {}


    create_activity_log_tables
    create_activity_log_trigger
  end
end
