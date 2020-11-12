class RemoveChangedFromManualInvestigations < ActiveRecord::Migration
  def change
    remove_column :manual_investigations, :changed, :string
  end
end
