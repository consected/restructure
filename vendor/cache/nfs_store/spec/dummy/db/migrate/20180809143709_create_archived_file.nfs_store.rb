# This migration comes from nfs_store (originally 20180801141505)
class CreateArchivedFile < ActiveRecord::Migration
  def change
    create_table :nfs_store_archived_files do |t|
      t.string "file_hash"
      t.string "file_name", null: false
      t.string "content_type", null: false
      t.string :archive_file, null: false
      t.string :path, null: false
      t.integer "file_size", null: false
      t.datetime "file_updated_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.belongs_to :nfs_store_container, index: true, foreign_key: true
      t.belongs_to :user, foreign_key: true
    end
  end
end
