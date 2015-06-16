class CreateTrackers < ActiveRecord::Migration
  def change
    create_table :trackers do |t|
      t.references :master, index: true, foreign_key: true
      t.references :protocol, index: true, foreign_key: true
      t.string :event
      t.datetime :event_date
      t.string :c_method
      t.string :outcome
      t.datetime :outcome_date
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
