class CreateScantrons < ActiveRecord::Migration
  def change
    create_table :scantrons do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.integer :scantron_id
      t.string :source
      t.integer :rank
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
