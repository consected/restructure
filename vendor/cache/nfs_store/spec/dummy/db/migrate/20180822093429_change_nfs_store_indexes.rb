class ChangeNfsStoreIndexes < ActiveRecord::Migration
  def change
    remove_index :nfs_store_stored_files, name: 'nfs_store_stored_files_unique_file'
    add_index :nfs_store_stored_files, [:nfs_store_container_id, :file_hash, :file_name, :path], unique: true, name: 'nfs_store_stored_files_unique_file'

  end
end
