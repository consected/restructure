class AddDisabledToProtocolOutcomes < ActiveRecord::Migration
  def change
    add_column :protocol_outcomes, :disabled, :boolean
  end
end
