# frozen_string_literal: true

require 'active_record/migration/app_generator'
class UpdateActivityLogPlayerContactPhonesQea6pe < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ml_app'
    self.table_name = 'activity_log_player_contact_phones'
    self.belongs_to_model = 'player_contact'
    self.fields = %i[data select_call_direction select_who called_when select_result select_next_step follow_up_when notes protocol_id set_related_player_contact_rank]
    self.table_comment = 'Phone Log process for Zeus'
    self.fields_comments = { "data": 'Phone number related to this activity', "select_call_direction": 'Was this call received by staff or to subject' }

    # added: []
    # removed: []

    # new fields comments: {:data=>"Phone number related to this activity", :select_call_direction=>"Was this call received by staff or to subject"}

    update_fields

    create_activity_log_trigger
  end
end
