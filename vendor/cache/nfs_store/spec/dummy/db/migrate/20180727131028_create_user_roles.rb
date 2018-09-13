class CreateUserRoles < ActiveRecord::Migration
def change
    create_table :user_roles do |t|
      t.integer :app_type
      t.string :role_name
      t.references :user, index: true, foreign_key: true
      t.integer :admin
      t.boolean :disabled, default: false, null: false
      t.timestamps null: false
    end
  end
end
