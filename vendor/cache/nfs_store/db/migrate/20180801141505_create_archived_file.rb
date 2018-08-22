class CreateArchivedFile < ActiveRecord::Migration
  def change
    create_table :nfs_store_archived_files do |t|
      t.string "file_hash", null: false
      t.string "file_name", null: false
      t.string "content_type", null: false
      t.string :archive_file, null: false
      t.string :path, null: false
      t.bigint "file_size", null: false
      t.datetime "file_updated_at"
      t.belongs_to :nfs_store_container, index: true, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.timestamps

    end
  end
end
