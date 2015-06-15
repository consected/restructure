class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.belongs_to :master, index: true, foreign_key: true
      t.string :street
      t.string :street2
      t.string :street3
      t.string :city
      t.string :state
      t.string :zip
      t.string :source
      t.integer :rank
      t.string :type
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
