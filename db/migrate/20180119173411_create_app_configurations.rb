class CreateAppConfigurations < ActiveRecord::Migration
  def change
    create_table :app_configurations do |t|
      t.string :name
      t.string :value
      t.boolean :disabled
      t.references :admin, index: true, foreign_key: true
    end
  end
end
