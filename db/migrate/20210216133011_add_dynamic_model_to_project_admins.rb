require 'active_record/migration/sql_helpers'

class AddDynamicModelToProjectAdmins < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers
  def change
    add_column 'ref_data.redcap_project_admins', :dynamic_model_table, :string
    add_column 'ref_data.redcap_project_admin_history', :dynamic_model_table, :string

    create_general_admin_history_trigger('ref_data',
                                         :redcap_project_admins,
                                         %i[
                                           name
                                           api_key
                                           server_url
                                           captured_project_info
                                           study
                                           transfer_mode
                                           frequency
                                           status
                                           post_transfer_pipeline
                                           notes
                                           dynamic_model_table
                                         ])
  end
end
