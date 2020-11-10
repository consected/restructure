class AddDisabledToItemFlag < ActiveRecord::Migration
  def change
    add_column :item_flags, :disabled, :boolean
  end
end
