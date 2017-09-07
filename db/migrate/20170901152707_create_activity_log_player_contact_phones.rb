class CreateActivityLogPlayerContactPhones < ActiveRecord::Migration
  def change
    create_table :activity_log_player_contact_phones do |t|
      t.string :select_call_direction
      t.string :select_who
      t.date :completed_when
      t.references :user, index: true, foreign_key: true
      t.references :player_contact, index: true, foreign_key: true
      t.references :master, index: true, foreign_key: true
      t.boolean :disabled
      t.string :notes

      t.timestamps null: false

    end
  end
end
