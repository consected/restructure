require 'active_record/migration/app_generator'
class UpdateIpaPsSleepsQghtxa < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_sleeps'
    self.fields = %i[form_version sleep_disorder_blank_yes_no_dont_know sleep_disorder_details sleep_apnea_device_no_yes number_of_nights_sleep_apnea_device sleep_apnea_travel_with_device_yes_no sleep_apnea_bring_device_yes_no sleep_apnea_device_details bed_and_wake_time_details]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[sleep_disorder_blank_yes_no_dont_know sleep_disorder_details sleep_apnea_device_no_yes sleep_apnea_device_details bed_and_wake_time_details]
    # added: ["form_version", "number_of_nights_sleep_apnea_device", "sleep_apnea_travel_with_device_yes_no", "sleep_apnea_bring_device_yes_no"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
