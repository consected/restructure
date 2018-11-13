class AddTimestampsToNfsStoreFilters < ActiveRecord::Migration
  def change
    change_table :nfs_store_filters do |t|
      t.timestamps
    end

  end
end
