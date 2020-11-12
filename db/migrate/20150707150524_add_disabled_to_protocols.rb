class AddDisabledToProtocols < ActiveRecord::Migration
  def change
    add_column :protocols, :disabled, :boolean
  end
end
