class RemoveTableProtocolOutcomes < ActiveRecord::Migration
  def change
    drop_table :protocol_outcomes
  end
end
