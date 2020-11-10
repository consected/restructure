class CreateProtocolEvents < ActiveRecord::Migration
  def change
    create_table :protocol_events do |t|
      t.string :name
      t.belongs_to :protocol, index: true, foreign_key: true
      t.references :admin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
