class CreateUserPreference < ActiveRecord::Migration[5.2]
  def change
    create_table :user_preferences do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.string :date_format
      t.string :pattern_for_date_format
      t.string :pattern_for_date_time_format
      t.string :pattern_for_time_format

      t.timestamps
    end
  end
end
