class RemoveColumnsFromUserPreferences < ActiveRecord::Migration[5.2]
  def change
    remove_column :user_preferences, :pattern_for_date_format, :string
    remove_column :user_preferences, :pattern_for_date_time_format, :string
    remove_column :user_preferences, :pattern_for_time_format, :string
  end
end
