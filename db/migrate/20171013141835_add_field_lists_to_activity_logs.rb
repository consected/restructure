class AddFieldListsToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :field_list, :string
    add_column :activity_logs, :blank_log_field_list, :string
  end
end
