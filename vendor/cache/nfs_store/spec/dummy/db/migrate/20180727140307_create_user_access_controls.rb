class CreateUserAccessControls < ActiveRecord::Migration
  def change
    create_table :user_access_controls do |t|

      t.timestamps
    end
  end
end
