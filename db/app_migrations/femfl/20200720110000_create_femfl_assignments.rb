# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateFemflAssignments < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'femfl_assignments'

    create_external_identifier_tables :femfl_id
    create_external_identifier_trigger :femfl_id
  end
end
