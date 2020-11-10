class AddButtonNameToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :main_log_name, :string
  end
end
