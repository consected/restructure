require 'active_record/migration/app_generator'
class UpdateIpaPsFootballExperiencesQghty5 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_football_experiences'
    self.fields = %i[played_in_nfl_blank_yes_no age]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[age played_in_nfl_blank_yes_no played_before_nfl_blank_yes_no football_experience_notes]
    # added: []
    # removed: ["played_before_nfl_blank_yes_no", "football_experience_notes"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
