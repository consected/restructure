class CreateUserPreference < ActiveRecord::Migration[5.2]
  def change
    create_table :user_preferences do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.belongs_to :time_zone, null: true
      t.string :date_format, null: true
      t.string :pattern_for_date_format, null: true
      t.string :pattern_for_date_time_format, null: true
      t.string :pattern_for_time_format, null: true

      t.timestamps
    end
  end
end
