class AddDisabledToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :disabled, :boolean
  end
end
