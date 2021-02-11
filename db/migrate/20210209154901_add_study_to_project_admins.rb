require 'active_record/migration/sql_helpers'
class AddStudyToProjectAdmins < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers
  def change
    add_column 'ref_data.redcap_project_admins', :study, :string
    add_column 'ref_data.redcap_project_admin_history', :study, :string

    create_general_admin_history_trigger('ref_data',
                                         :redcap_project_admins,
                                         %i[
                                           name
                                           api_key
                                           server_url
                                           captured_project_info
                                           study
                                         ])
  end
end
