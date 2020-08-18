require 'active_record/migration/app_generator'
class UpdatePittBhiAppointmentsQf9g8c < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_appointments'
    self.fields = %i[visit_start_date visit_end_date select_status notes]
    self.table_comment = 'PITT BHI study participation dates and status'
    self.fields_comments = {}


    self.prev_fields = %i[visit_start_date visit_end_date select_status notes]
    # added: []
    # removed: []
    # new table comment: PITT BHI study participation dates and status
    
    update_fields

    create_dynamic_model_trigger
  end
end
