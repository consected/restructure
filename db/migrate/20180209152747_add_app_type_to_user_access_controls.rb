class AddAppTypeToUserAccessControls < ActiveRecord::Migration
  def change
    add_reference :user_access_controls, :app_type, index: true, foreign_key: true
  end
end
