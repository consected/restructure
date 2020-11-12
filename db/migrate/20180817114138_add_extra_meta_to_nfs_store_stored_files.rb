class AddExtraMetaToNfsStoreStoredFiles < ActiveRecord::Migration
  def change
    add_column :nfs_store_stored_files, :title, :string
    add_column :nfs_store_stored_files, :tags, :string, array: true
    add_column :nfs_store_stored_files, :description, :string
  end
end
