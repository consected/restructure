class AddStoredFileToNfsStoreArchivedFile < ActiveRecord::Migration
  def change
    add_reference :nfs_store_archived_files, :nfs_store_stored_file, index: true, foreign_key: true
  end
end
