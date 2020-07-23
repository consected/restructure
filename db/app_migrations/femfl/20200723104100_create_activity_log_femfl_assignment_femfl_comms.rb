# frozen_string_literal: true

require 'active_record/migration/app_generator'
class CreateActivityLogFemflAssignmentFemflComms < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'activity_log_femfl_assignment_femfl_comms'
    self.belongs_to_model = 'femfl_assignment'
    self.fields = %i[select_activity activity_date placeholder_communication placeholder_follow_up select_record_from_dynamic_model__femfl_contacts select_record_from_dynamic_model__femfl_addresses select_direction select_who select_result select_next_step follow_up_when follow_up_time notes]

    create_activity_log_tables
    create_activity_log_trigger
  end
end
