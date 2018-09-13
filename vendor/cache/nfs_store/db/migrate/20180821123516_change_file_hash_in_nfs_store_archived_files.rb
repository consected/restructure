class ChangeFileHashInNfsStoreArchivedFiles < ActiveRecord::Migration
  def change
    change_column :nfs_store_archived_files, :file_hash, :string, null: true
  end
end
