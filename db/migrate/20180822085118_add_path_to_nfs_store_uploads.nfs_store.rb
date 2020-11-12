# This migration comes from nfs_store (originally 20180822085021)
class AddPathToNfsStoreUploads < ActiveRecord::Migration
  def change
    add_column :nfs_store_uploads, :path, :string
  end
end
