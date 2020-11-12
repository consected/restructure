class AddExtrasToDynamicModels < ActiveRecord::Migration
  def change
    add_column :dynamic_models, :position, :integer
    add_column :dynamic_models, :category, :string
  end
end
