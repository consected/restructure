require 'active_record/migration/app_generator'
class CreatePittBhiPsEligiblesQf1owc < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_eligibles'
    self.fields = %i[interested_yes_no notes not_interested_notes consent_to_pass_info_to_msm_yes_no consent_to_pass_info_to_msm_2_yes_no contact_info_notes more_questions_yes_no more_questions_notes select_still_interested]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
