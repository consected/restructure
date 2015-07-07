class AddDisabledToAccuracyScores < ActiveRecord::Migration
  def change
    add_column :accuracy_scores, :disabled, :boolean
  end
end
