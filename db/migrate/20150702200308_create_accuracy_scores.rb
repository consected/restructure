class CreateAccuracyScores < ActiveRecord::Migration
  def change
    create_table :accuracy_scores do |t|
      t.string :name
      t.integer :value
      t.references :admin, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
