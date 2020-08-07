class AddCategoryToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :category, :string
  end
end
