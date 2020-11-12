# This migration comes from nfs_store (originally 20180821123516)
class ChangeFileHashInNfsStoreArchivedFiles < ActiveRecord::Migration
  def change
    change_column :nfs_store_archived_files, :file_hash, :string, null: true
  end
end
