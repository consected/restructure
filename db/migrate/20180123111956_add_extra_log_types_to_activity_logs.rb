class AddExtraLogTypesToActivityLogs < ActiveRecord::Migration
  def change
    add_column :activity_logs, :blank_log_name, :string
    add_column :activity_logs, :extra_log_types, :string
    add_column :activity_logs, :hide_item_list_panel, :boolean
  end
end
