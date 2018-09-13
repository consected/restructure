class AddPathToNfsStoreUploads < ActiveRecord::Migration
  def change
    add_column :nfs_store_uploads, :path, :string
  end
end
