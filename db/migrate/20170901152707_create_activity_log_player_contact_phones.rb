class CreateActivityLogPlayerContactPhones < ActiveRecord::Migration
  def change
    create_table :activity_log_player_contact_phones do |t|
      t.string :data
      t.string :select_call_direction
      t.string :select_who
      t.date :called_when      
      t.string  :select_result
      t.string  :select_next_step
      t.date  :follow_up_when
      t.references :protocol, index: true, foreign_key: true
      t.references :sub_process, index: true, foreign_key: true
      t.references :protocol_event, index: true, foreign_key: true
      t.references :tracker_history, index: true, references: :tracker_history
      t.string :notes

      t.references :user, index: true, foreign_key: true
      t.references :player_contact, index: true, foreign_key: true
      t.references :master, index: true, foreign_key: true
      t.boolean :disabled
      
      t.timestamps null: false

    end
  end
end
