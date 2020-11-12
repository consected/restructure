class AddMasterToNfsStoreContainers < ActiveRecord::Migration
  def change
    add_reference :nfs_store_containers, :master, index: true, foreign_key: true
  end
end
