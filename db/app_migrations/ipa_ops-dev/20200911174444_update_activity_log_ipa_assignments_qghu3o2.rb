require 'active_record/migration/app_generator'
class UpdateActivityLogIpaAssignmentsQghu3o2 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_assignment'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_assignments'
    self.fields = %i[select_who select_record_from_player_contacts follow_up_when follow_up_time notes select_activity activity_date select_record_from_addresses select_direction select_result select_next_step]
    self.table_comment = ''
    self.fields_comments = {}

    self.prev_fields = %i[ipa_assignment_id select_activity activity_date select_record_from_player_contacts select_direction select_who select_result select_next_step follow_up_when follow_up_time notes protocol_id select_record_from_addresses]
    # added: []
    # removed: ["protocol_id"]

    update_fields

    create_activity_log_trigger
  end
end
