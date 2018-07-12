class CreateFileStorageResources < ActiveRecord::Migration
  def change
    create_table :file_storage_resources do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.string :name
      t.string :s3_url
      t.string :notes
      t.belongs_to :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
