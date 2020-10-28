class AddExtraMetaToNfsStoreArchivedFiles < ActiveRecord::Migration
  def change
    add_column :nfs_store_archived_files, :title, :string
    add_column :nfs_store_archived_files, :tags, :string, array: true
    add_column :nfs_store_archived_files, :description, :string
  end
end
