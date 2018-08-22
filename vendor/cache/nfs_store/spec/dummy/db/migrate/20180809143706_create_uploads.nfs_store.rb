# This migration comes from nfs_store (originally 20180716153050)
class CreateUploads < ActiveRecord::Migration
  def change
    create_table :nfs_store_uploads do |t|
      t.string   "file_hash", unique: true, null: false
      t.string   "file_name", null: false
      t.string   "content_type", null: false
      t.integer  "file_size", null: false
      t.integer  "chunk_count"
      t.boolean  "completed"
      t.datetime "file_updated_at"
      t.belongs_to :user, foreign_key: true
      t.belongs_to :nfs_store_container, foreign_key: true
      t.timestamps
    end
  end
end
