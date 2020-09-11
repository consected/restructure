require 'active_record/migration/app_generator'
class UpdateIpaPsMrisQghrzk < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_mris'
    self.fields = %i[form_version past_mri_yes_no_dont_know past_mri_details metal_implants_blank_yes_no_dont_know metal_implants_details electrical_implants_blank_yes_no_dont_know electrical_implants_details metal_jewelry_blank_yes_no hearing_aid_blank_yes_no radiation_blank_yes_no select_radiation_type radiation_details]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[electrical_implants_blank_yes_no_dont_know electrical_implants_details metal_implants_blank_yes_no_dont_know metal_implants_details metal_jewelry_blank_yes_no hearing_aid_blank_yes_no past_mri_yes_no_dont_know past_mri_details radiation_blank_yes_no radiation_details]
    # added: ["form_version", "select_radiation_type"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
