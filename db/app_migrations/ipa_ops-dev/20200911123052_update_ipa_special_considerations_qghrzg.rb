require 'active_record/migration/app_generator'
class UpdateIpaSpecialConsiderationsQghrzg < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_special_considerations'
    self.fields = %i[travel_with_wife_yes_no travel_with_wife_details tmoca_score mmse_yes_no mmse_details bringing_cpap_yes_no tms_exempt_yes_no taking_med_for_mri_pet_yes_no same_hotel_yes_no]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[travel_with_wife_yes_no travel_with_wife_details mmse_yes_no tmoca_score bringing_cpap_yes_no tms_exempt_yes_no taking_med_for_mri_pet_yes_no mmse_details]
    # added: ["same_hotel_yes_no"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
