class RemoveIndexFromNfsStoreUploads < ActiveRecord::Migration
  def change
    remove_index :nfs_store_uploads, name: 'nfs_store_uploads_unique_file'
  end
end
