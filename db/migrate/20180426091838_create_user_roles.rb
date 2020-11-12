class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.references :app_type, index: true, foreign_key: true
      t.string :role_name
      t.references :user, index: true, foreign_key: true
      t.references :admin, index: true, foreign_key: true
      t.boolean :disabled, default: false, null: false
      t.timestamps null: false
    end
  end
end
