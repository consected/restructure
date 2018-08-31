class RemoveTagsFromFiles < ActiveRecord::Migration
  def change
    remove_column :nfs_store_archived_files, :tags, :string
    remove_column :nfs_store_stored_files, :tags, :string
  end
end
