class AddTimestampsToAppTypes < ActiveRecord::Migration
  def change
    change_table :app_types do |t|
        t.timestamps
    end
  end
end
