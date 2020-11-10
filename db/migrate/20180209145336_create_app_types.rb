class CreateAppTypes < ActiveRecord::Migration
  def change
    create_table :app_types do |t|
      t.string :name
      t.string :label
      t.boolean :disabled
      t.references :admin, index: true, foreign_key: true
    end
  end
end
