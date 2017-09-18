class AddDisabledToProtocolOutcomes < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'protocol_outcomes'
      add_column :protocol_outcomes, :disabled, :boolean
    end
  end
end
