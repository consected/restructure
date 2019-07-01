class ChangeNfsStoreIndexes < ActiveRecord::Migration
  def change
    begin
      remove_index :nfs_store_stored_files, name: 'nfs_store_stored_files_unique_file'
    rescue => e
      puts "remove_index :nfs_store_uploads, name: 'nfs_store_stored_files' failed because the index doesn't exist.\n#{e}"
    end

    add_index :nfs_store_stored_files, [:nfs_store_container_id, :file_hash, :file_name, :path], unique: true, name: 'nfs_store_stored_files_unique_file'

  end
end
