class AddUploadSetToNfsStoreUploads < ActiveRecord::Migration
  def change
    add_column :nfs_store_uploads, :upload_set, :string, index: true
    add_index :nfs_store_uploads, :upload_set
  end
end
