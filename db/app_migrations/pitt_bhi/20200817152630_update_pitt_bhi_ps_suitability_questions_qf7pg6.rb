require 'active_record/migration/app_generator'
class UpdatePittBhiPsSuitabilityQuestionsQf7pg6 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_suitability_questions'
    self.fields = %i[birth_date eligible_pension_yes_no age notes]
    self.table_comment = ''
    self.fields_comments = {}

    self.prev_fields = %i[birth_date eligible_pension_yes_no notes]
    # added: ["age"]
    # removed: ["any_questions_yes_no"]

    update_fields

    create_dynamic_model_trigger
  end
end
