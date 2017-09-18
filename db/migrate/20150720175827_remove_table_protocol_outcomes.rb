class RemoveTableProtocolOutcomes < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'protocol_outcomes'
      drop_table :protocol_outcomes
    end
  end
end
