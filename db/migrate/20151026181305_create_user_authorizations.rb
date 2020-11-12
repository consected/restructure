class CreateUserAuthorizations < ActiveRecord::Migration
  def change
    create_table :user_authorizations do |t|
      t.references :user
      t.string :has_authorization
      t.references :admin
      t.boolean :disabled

      t.timestamps null: false
    end
  end
end
