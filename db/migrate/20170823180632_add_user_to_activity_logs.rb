class AddUserToActivityLogs < ActiveRecord::Migration
  def change
    add_reference :activity_logs, :user, index: true, foreign_key: true
  end
end
