class AddDisabledToItemFlagNames < ActiveRecord::Migration
  def change
    add_column :item_flag_names, :disabled, :boolean
    add_reference :item_flag_names, :admin, index: true, foreign_key: true


  end
end
