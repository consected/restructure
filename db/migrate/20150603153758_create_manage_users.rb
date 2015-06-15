class CreateManageUsers < ActiveRecord::Migration
  def change
    create_table :manage_users do |t|

      t.timestamps null: false
    end
  end
end
