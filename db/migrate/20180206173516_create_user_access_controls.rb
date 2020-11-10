class CreateUserAccessControls < ActiveRecord::Migration
  def change
    create_table :user_access_controls do |t|
      t.references :user
      t.string :resource_type
      t.string :resource_name
      t.string :options
      t.string :access
      t.boolean :disabled
      t.references :admin
    end
  end
end
