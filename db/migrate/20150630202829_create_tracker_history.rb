class CreateTrackerHistory < ActiveRecord::Migration
  def change
    create_table :tracker_history do |t|
      t.references :master, index: true, foreign_key: true
      t.references :protocol, index: true, foreign_key: true
      t.references :tracker, index: true, foreign_key: true
      t.string :event
      t.datetime :event_date
      t.string :c_method
      t.string :outcome
      t.datetime :outcome_date
      t.references :user, index: true, foreign_key: true
      t.string :notes
      t.timestamps null: false
    end
  end
end
