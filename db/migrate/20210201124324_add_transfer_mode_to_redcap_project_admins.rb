require 'active_record/migration/sql_helpers'

class AddTransferModeToRedcapProjectAdmins < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    add_column 'ref_data.redcap_project_admins', :transfer_mode, :string
    add_column 'ref_data.redcap_project_admins', :frequency, :string
    add_column 'ref_data.redcap_project_admins', :status, :string
    add_column 'ref_data.redcap_project_admins', :post_transfer_pipeline, :string, array: true, default: []
    add_column 'ref_data.redcap_project_admins', :notes, :string

    add_column 'ref_data.redcap_project_admin_history', :transfer_mode, :string
    add_column 'ref_data.redcap_project_admin_history', :frequency, :string
    add_column 'ref_data.redcap_project_admin_history', :status, :string
    add_column 'ref_data.redcap_project_admin_history', :post_transfer_pipeline, :string, array: true, default: []
    add_column 'ref_data.redcap_project_admin_history', :notes, :string

    create_general_admin_history_trigger('ref_data',
                                         :redcap_project_admins,
                                         %i[
                                           name
                                           api_key
                                           server_url
                                           captured_project_info
                                           transfer_mode
                                           frequency
                                           status
                                           post_transfer_pipeline
                                           notes
                                         ])
  end
end
