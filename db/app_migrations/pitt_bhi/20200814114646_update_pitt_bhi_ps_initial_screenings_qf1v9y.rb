require 'active_record/migration/app_generator'
class UpdatePittBhiPsInitialScreeningsQf1v9y < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_initial_screenings'
    self.fields = %i[select_is_good_time_to_speak question_notes select_still_interested follow_up_date follow_up_time notes]
    self.table_comment = ''
    self.fields_comments = {}


    # added: []
    # removed: ["any_questions_blank_yes_no", "more_questions_yes_no", "more_questions_notes", "still_interested_2_yes_no"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
