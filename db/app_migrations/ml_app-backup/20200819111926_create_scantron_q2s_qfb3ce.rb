require 'active_record/migration/app_generator'
class CreateScantronQ2sQfb3ce < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ml_app'
    self.table_name = 'scantron_q2s'
    self.fields = %i[q2_scantron_id]
    self.table_comment = ''
    self.fields_comments = {}


    create_external_identifier_tables :q2_scantron_id, :bigint
    create_external_identifier_trigger :q2_scantron_id
  end
end
