# This migration comes from nfs_store (originally 20180810095541)
class AddNfsStoreIndexes < ActiveRecord::Migration
  def change
    add_index :nfs_store_uploads, [:nfs_store_container_id, :file_hash, :file_name], unique: true, name: 'nfs_store_uploads_unique_file'
    add_index :nfs_store_stored_files, [:nfs_store_container_id, :file_hash, :file_name], unique: true, name: 'nfs_store_stored_files_unique_file'
    # add_index :nfs_store_archived_files, [:container_id, :file_hash, :archive_file, :file_name], unique: true, name: 'nfs_store_archived_files_unique_file'
  end
end
