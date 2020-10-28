class AddCurrentAppTypeIdToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :app_type, index: true, foreign_key: true
  end
end
