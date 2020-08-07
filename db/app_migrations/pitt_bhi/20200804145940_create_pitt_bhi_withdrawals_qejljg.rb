require 'active_record/migration/app_generator'
class CreatePittBhiWithdrawalsQejljg < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_withdrawals'
    self.fields = %i[select_subject_withdrew_reason select_investigator_terminated lost_to_follow_up_no_yes no_longer_participating_no_yes notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
