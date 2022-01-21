class CreateTimeZones < ActiveRecord::Migration[5.2]
  def change
    create_table :time_zones do |t|
      t.string :abbreviation
      t.string :name, index: { unique: true }
      t.string :utc_offset

      t.timestamps
    end
  end
end
