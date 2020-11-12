class AddTimestampsToNfsStoreContainers < ActiveRecord::Migration
  def change
    add_column :nfs_store_containers, :created_at, :datetime
    add_column :nfs_store_containers, :updated_at, :datetime

  end
end
