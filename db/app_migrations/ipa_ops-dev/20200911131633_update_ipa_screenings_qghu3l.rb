require 'active_record/migration/app_generator'
class UpdateIpaScreeningsQghu3l < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_screenings'
    self.fields = %i[eligible_for_study_blank_yes_no requires_study_partner_blank_yes_no notes good_time_to_speak_blank_yes_no callback_date callback_time still_interested_blank_yes_no ineligible_notes eligible_notes not_interested_notes contact_in_future_yes_no]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[eligible_for_study_blank_yes_no notes good_time_to_speak_blank_yes_no callback_date callback_time still_interested_blank_yes_no not_interested_notes ineligible_notes eligible_notes eligible_with_partner_notes requires_study_partner_blank_yes_no contact_in_future_yes_no]
    # added: []
    # removed: ["eligible_with_partner_notes"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
