class AddPathToNfsStoreImportsAgain < ActiveRecord::Migration[5.2]
  def change
    return if NfsStore::Import.attribute_names.include? 'path'

    add_column :nfs_store_imports, :path, :string
  end
end
