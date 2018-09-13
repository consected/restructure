class AddAppTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :app_type_id, :integer
  end
end
