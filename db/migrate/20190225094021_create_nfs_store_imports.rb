class CreateNfsStoreImports < ActiveRecord::Migration
  def change
    create_table :nfs_store_imports do |t|
      t.string :file_hash
      t.string :file_name
      t.belongs_to :user, foreign_key: true
      t.belongs_to :nfs_store_container, foreign_key: true
      t.timestamps
    end
  end
end
