require 'active_record/migration/app_generator'
class CreatePittBhiAssignmentsQejfou < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'data_requests'
    self.table_name = 'pitt_bhi_assignments'
    self.fields = %i[pitt_bhi_id]
    self.table_comment = ''
    self.fields_comments = {}


    create_external_identifier_tables :pitt_bhi_id, :bigint
    create_external_identifier_trigger :pitt_bhi_id
  end
end
