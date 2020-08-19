require 'active_record/migration/app_generator'
class UpdateIpaRecruitmentRanksQfb3ce < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ml_app'
    self.table_name = 'ipa_recruitment_ranks'
    self.fields = %i[eligible]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[rank ml_app_age_eligible_for_ipa]
    # added: ["eligible"]
    # removed: ["rank", "ml_app_age_eligible_for_ipa"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
