class AddPathToNfsStoreImports < ActiveRecord::Migration[5.2]
  def change
    add_column :nfs_store_imports, :path, :string
  end
end
