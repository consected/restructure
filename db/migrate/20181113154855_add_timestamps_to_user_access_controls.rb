class AddTimestampsToUserAccessControls < ActiveRecord::Migration
  def change
    change_table :user_access_controls do |t|
        t.timestamps
    end
  end
end
