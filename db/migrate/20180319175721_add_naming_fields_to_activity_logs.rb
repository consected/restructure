class AddNamingFieldsToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :process_name, :string
    add_column :activity_logs, :table_name, :string
  end
end
