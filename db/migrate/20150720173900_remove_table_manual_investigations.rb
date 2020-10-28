class RemoveTableManualInvestigations < ActiveRecord::Migration
  def change
	drop_table :manual_investigations
  end
end
