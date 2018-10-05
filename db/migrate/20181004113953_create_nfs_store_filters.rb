class CreateNfsStoreFilters < ActiveRecord::Migration
  def change
    create_table :nfs_store_filters do |t|
      t.references :app_type, index: true, foreign_key: true
      t.string :role_name
      t.references :user, index: true, foreign_key: true
      t.string :resource_name
      t.string :filter
      t.string :description
      t.boolean :disabled
      t.references :admin, index: true, foreign_key: true
    end
  end
end
