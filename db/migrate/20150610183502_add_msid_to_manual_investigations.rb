class AddMsidToManualInvestigations < ActiveRecord::Migration
  def change
    add_reference :manual_investigations, :master, index: true, foreign_key: true
  end
end
