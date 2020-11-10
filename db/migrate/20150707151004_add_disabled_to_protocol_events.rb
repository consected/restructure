class AddDisabledToProtocolEvents < ActiveRecord::Migration
  def change
    add_column :protocol_events, :disabled, :boolean
  end
end
