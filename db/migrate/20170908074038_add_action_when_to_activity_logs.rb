class AddActionWhenToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :action_when_attribute, :string
  end
end
