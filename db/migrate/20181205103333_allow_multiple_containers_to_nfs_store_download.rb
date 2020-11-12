class AllowMultipleContainersToNfsStoreDownload < ActiveRecord::Migration
  def change

    change_column_null :nfs_store_downloads, :nfs_store_container_id,  true
    add_column :nfs_store_downloads, :nfs_store_container_ids, :integer, array: true

  end
end
