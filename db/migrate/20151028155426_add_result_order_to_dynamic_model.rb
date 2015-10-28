class AddResultOrderToDynamicModel < ActiveRecord::Migration
  def change
    add_column :dynamic_models, :result_order, :string
  end
end
