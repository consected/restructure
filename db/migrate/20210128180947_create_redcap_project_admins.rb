require 'active_record/migration/sql_helpers'

class CreateRedcapProjectAdmins < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    table_comment = 'Redcap project administration'
    history_table_comment = "#{table_comment} - history"

    create_table(:redcap_project_admins, comment: table_comment) do |t|
      t.string :name
      t.string :api_key
      t.string :server_url
      t.jsonb :captured_project_info
      t.boolean :disabled
      t.references :admin
      t.timestamps null: false
    end

    create_table(:redcap_project_admin_history, comment: history_table_comment) do |t|
      t.belongs_to :redcap_project_admin
      t.string :name
      t.string :api_key
      t.string :server_url
      t.jsonb :captured_project_info
      t.boolean :disabled
      t.references :admin
      t.timestamps null: false
    end

    create_general_admin_history_trigger('ml_app',
                                         :redcap_project_admins,
                                         %i[
                                           name
                                           api_key
                                           server_url
                                           captured_project_info
                                         ])
  end
end
