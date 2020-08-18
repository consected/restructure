require 'active_record/migration/app_generator'
class UpdatePittBhiPsNonEligiblesQf9ekk < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_non_eligibles'
    self.fields = %i[notes]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[any_questions_yes_no notes contact_pi_yes_no additional_questions_yes_no consent_to_pass_info_to_msm_yes_no consent_to_pass_info_to_msm_2_yes_no contact_info_notes]
    # added: []
    # removed: ["any_questions_yes_no", "contact_pi_yes_no", "additional_questions_yes_no", "consent_to_pass_info_to_msm_yes_no", "consent_to_pass_info_to_msm_2_yes_no", "contact_info_notes"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
