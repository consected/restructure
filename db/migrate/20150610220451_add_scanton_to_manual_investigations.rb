class AddScantonToManualInvestigations < ActiveRecord::Migration
  def change
    add_reference :manual_investigations, :scantron, index: true, foreign_key: true
    remove_column :player_infos, :scantron_id
  end
end
