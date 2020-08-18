require 'active_record/migration/app_generator'
class UpdatePittBhiPsSuitabilityQuestionsQf92is < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_suitability_questions'
    self.fields = %i[birth_date eligible_pension_yes_no age notes]
    self.table_comment = 'Suitability assessment form for BHI phone screening, recording responses from subject
'
    self.fields_comments = {"birth_date":"Date of birth","eligible_pension_yes_no":"Eligible for a pension from the NFL\n(At least 3 seasons with 3 games per season)\n","age":"Calculated age at the time the response was saved","notes":"Question and notes recorded by interviewer"}


    self.prev_fields = %i[birth_date eligible_pension_yes_no notes age]
    # added: []
    # removed: []
    # new table comment: Suitability assessment form for BHI phone screening, recording responses from subject\n
    # new fields comments: [:birth_date, :eligible_pension_yes_no, :age, :notes]
    update_fields

    create_dynamic_model_trigger
  end
end
