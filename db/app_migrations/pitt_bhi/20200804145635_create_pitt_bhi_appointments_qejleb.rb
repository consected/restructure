require 'active_record/migration/app_generator'
class CreatePittBhiAppointmentsQejleb < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_appointments'
    self.fields = %i[visit_start_date visit_end_date select_status notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
