class RemoveUserFromProtocols < ActiveRecord::Migration
  def change
    remove_column :protocols, :user_id, :integer
  end
end
