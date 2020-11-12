class RemoveIndexFromNfsStoreUploads < ActiveRecord::Migration
  def change
    begin
      remove_index :nfs_store_uploads, name: 'nfs_store_uploads_unique_file'
    rescue => e
      puts "remove_index :nfs_store_uploads, name: 'nfs_store_uploads_unique_file' failed because the index doesn't exist.\n#{e}"
    end
  end
end
