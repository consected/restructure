# frozen_string_literal: true

require 'active_record/migration/app_generator'
class UpdateActivityLogBhsAssignmentsThjdf < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ml_app'
    self.table_name = 'activity_log_bhs_assignments'
    self.belongs_to_model = 'bhs_assignment'
    self.fields = %i[select_record_from_player_contact_phones return_call_availability_notes questions_from_call_notes results_link select_result pi_notes_from_return_call pi_return_call_notes]

    # added: ["bhs_assignment_id"]
    # removed: []
    update_fields
    create_activity_log_trigger
  end
end
