class AddRankToManualInvestigations < ActiveRecord::Migration
  def change
    add_column :manual_investigations, :rank, :integer
  end
end
