require 'active_record/migration/app_generator'
class CreatePittBhiPsNonEligiblesQf1otq < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_non_eligibles'
    self.fields = %i[any_questions_yes_no notes contact_pi_yes_no additional_questions_yes_no consent_to_pass_info_to_msm_yes_no consent_to_pass_info_to_msm_2_yes_no contact_info_notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
