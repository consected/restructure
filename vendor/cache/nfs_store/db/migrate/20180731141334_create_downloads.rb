class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :nfs_store_downloads do |t|
      t.integer :user_groups, array: true, default: []
      t.string :path, null: true
      t.string :retrieval_path
      t.string :retrieved_items
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :nfs_store_container, foreign_key: true, null: false
      t.timestamps
    end
  end
end
