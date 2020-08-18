require 'active_record/migration/app_generator'
class CreatePittBhiAccessPittStaffsQf9cpx < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_access_pitt_staffs'
    self.fields = %i[]
    self.table_comment = 'A record referencing a master record indicates PITT BHI staff have access to this participant'
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
