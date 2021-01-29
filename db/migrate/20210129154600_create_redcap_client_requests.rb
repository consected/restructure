require 'active_record/migration/sql_helpers'

class CreateRedcapClientRequests < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::SqlHelpers

  def change
    # NOTE: there is intentionally no history table

    table_comment = 'Redcap client requests'

    create_table(:redcap_client_requests, comment: table_comment) do |t|
      t.belongs_to :redcap_project_admin
      t.string :action
      t.string :name
      t.string :server_url
      t.references :admin
      t.timestamps null: false
    end
  end
end
