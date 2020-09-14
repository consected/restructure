require 'active_record/migration/app_generator'
class UpdateIpaSurveysQghu3m < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_surveys'
    self.fields = %i[select_survey_type sent_date completed_date notes]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[select_survey_type sent_date completed_date send_next_survey_when notes]
    # added: []
    # removed: ["send_next_survey_when"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
