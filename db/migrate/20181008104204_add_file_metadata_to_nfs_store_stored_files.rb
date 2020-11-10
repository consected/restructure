class AddFileMetadataToNfsStoreStoredFiles < ActiveRecord::Migration
  def change

    unless NfsStore::Manage::StoredFile.attribute_names.include? 'file_metadata'
      add_column :nfs_store_stored_files, :file_metadata, :jsonb
      add_column :nfs_store_archived_files, :file_metadata, :jsonb
    end
  end
end
