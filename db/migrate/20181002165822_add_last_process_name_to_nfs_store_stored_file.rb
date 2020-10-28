class AddLastProcessNameToNfsStoreStoredFile < ActiveRecord::Migration
  def change
    add_column :nfs_store_stored_files, :last_process_name_run, :string
  end
end
