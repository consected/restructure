# frozen_string_literal: true

require 'active_record/migration/app_generator'
class UpdateSageAssignments < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ml_app'
    self.table_name = 'sage_assignments'
    self.fields = %i[sage_id]

    # added: []
    # removed: ["assigned_by"]
    update_fields
    create_external_identifier_trigger :sage_id
  end
end
