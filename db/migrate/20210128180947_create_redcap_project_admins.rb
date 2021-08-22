require 'active_record/migration/sql_helpers'
require 'active_record/migration/app_generator'

class CreateRedcapProjectAdmins < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ref_data'
    self.owner = 'fphs'
    create_schema

    table_comment = 'Redcap project administration'
    history_table_comment = "#{table_comment} - history"

    create_table('ref_data.redcap_project_admins', comment: table_comment) do |t|
      t.string :name
      t.string :api_key
      t.string :server_url
      t.jsonb :captured_project_info
      t.boolean :disabled
      t.references :admin
      t.timestamps null: false
    end

    create_table('ref_data.redcap_project_admin_history', comment: history_table_comment) do |t|
      t.belongs_to :redcap_project_admin, foreign_key: true,
                                          index: { name: 'idx_history_on_redcap_project_admin_id' }
      t.string :name
      t.string :api_key
      t.string :server_url
      t.jsonb :captured_project_info
      t.boolean :disabled
      t.references :admin
      t.timestamps null: false
    end

    create_general_admin_history_trigger('ref_data',
                                         :redcap_project_admins,
                                         %i[
                                           name
                                           api_key
                                           server_url
                                           captured_project_info
                                         ])
  end
end
