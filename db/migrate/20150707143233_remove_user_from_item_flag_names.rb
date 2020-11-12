class RemoveUserFromItemFlagNames < ActiveRecord::Migration
  def change
    remove_column :item_flag_names, :user_id, :integer
  end
end
