class CreatePlayerContacts < ActiveRecord::Migration
  def change
    create_table :player_contacts do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.string :type
      t.string :data
      t.string :source
      t.integer :rank
      t.boolean :active
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
