class AddCategoryToActivityLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_logs, :category, :string
  end
end
