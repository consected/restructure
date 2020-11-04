require 'active_record/migration/app_generator'
class UpdateIpaPsInitialScreeningsQhxk3k < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_initial_screenings'
    self.fields = %i[form_version select_is_good_time_to_speak looked_at_website_yes_no select_may_i_begin any_questions_blank_yes_no same_hotel_yes_no select_schedule select_still_interested follow_up_date follow_up_time notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false


    self.prev_fields = %i[select_is_good_time_to_speak any_questions_blank_yes_no follow_up_date follow_up_time notes looked_at_website_yes_no select_still_interested form_version same_hotel_yes_no embedded_report_ipa__ipa_appointments select_schedule select_may_i_begin]
    # added: []
    # removed: ["embedded_report_ipa__ipa_appointments"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
