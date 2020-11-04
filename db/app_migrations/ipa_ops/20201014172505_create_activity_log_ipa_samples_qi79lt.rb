require 'active_record/migration/app_generator'
class CreateActivityLogIpaSamplesQi79lt < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.belongs_to_model = 'ipa_sample'
    self.schema = 'ipa_ops'
    self.table_name = 'activity_log_ipa_samples'
    self.fields = %i[action_date action_time select_user_with_role_sample_registration notes select_transport_method recipient received_by select_storage_location requester reason request_date request_time select_user_with_role_sample_auth_withdraw select_issue_type duration]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false


    create_activity_log_tables
    create_activity_log_trigger
  end
end
