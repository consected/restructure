# Migration version added
# This migration comes from nfs_store (originally 20180731141334)
class CreateMoveActions < ActiveRecord::Migration[4.2]
  def change
    create_table :nfs_store_move_actions do |t|
      t.integer :user_groups, array: true # , default: []
      t.string :path, null: true
      t.string :new_path, null: true
      t.string :retrieval_path
      t.string :moved_items
      t.integer :nfs_store_container_ids, array: true, null: true
      t.belongs_to :user, foreign_key: true, null: false
      t.belongs_to :nfs_store_container, foreign_key: true, null: true
      t.timestamps
    end
  end
end
