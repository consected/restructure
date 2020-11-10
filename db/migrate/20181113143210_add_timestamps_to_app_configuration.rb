class AddTimestampsToAppConfiguration < ActiveRecord::Migration
  def change
    change_table :app_configurations do |t|
        t.timestamps
    end

  end
end
