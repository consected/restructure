require 'active_record/migration/app_generator'
class CreatePittBhiScreeningsQeynee < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_screenings'
    self.fields = %i[eligible_for_study_blank_yes_no good_time_to_speak_blank_yes_no still_interested_blank_yes_no callback_date callback_time consent_performed_yes_no did_subject_consent_yes_no ineligible_notes eligible_notes not_interested_notes contact_in_future_yes_no]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
