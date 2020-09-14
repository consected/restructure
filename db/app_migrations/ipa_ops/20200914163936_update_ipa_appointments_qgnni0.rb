require 'active_record/migration/app_generator'
class UpdateIpaAppointmentsQgnni0 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_appointments'
    self.fields = %i[covid19_test_date covid19_test_time visit_start_date visit_end_date select_schedule select_status notes]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[visit_start_date visit_end_date select_status notes select_schedule]
    # added: ["covid19_test_date", "covid19_test_time"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
