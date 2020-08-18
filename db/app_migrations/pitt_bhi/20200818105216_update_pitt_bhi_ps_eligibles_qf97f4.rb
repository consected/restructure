require 'active_record/migration/app_generator'
class UpdatePittBhiPsEligiblesQf97f4 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_eligibles'
    self.fields = %i[consent_to_pass_info_to_pitt_yes_no consent_to_pass_info_to_pitt_2_yes_no not_interested_notes contact_info_notes]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[contact_info_notes more_questions_yes_no more_questions_notes select_still_interested consent_to_pass_info_to_pitt_yes_no consent_to_pass_info_to_pitt_2_yes_no]
    # added: ["not_interested_notes"]
    # removed: ["more_questions_yes_no", "more_questions_notes", "select_still_interested"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
