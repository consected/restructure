require 'active_record/migration/app_generator'
class CreatePittBhiPsSuitabilityQuestionsQf1run < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_suitability_questions'
    self.fields = %i[birth_date eligible_pension_yes_no any_questions_yes_no notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
