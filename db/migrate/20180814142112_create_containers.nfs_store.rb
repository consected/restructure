# This migration comes from nfs_store (originally 20180715172016)
class CreateContainers < ActiveRecord::Migration
  def change
    create_table :nfs_store_containers do |t|
      t.string :name
      t.belongs_to :user, foreign_key: true
      t.belongs_to :app_type, foreign_key: true
      t.belongs_to :nfs_store_container, index: true, foreign_key: true

    end
  end
end
