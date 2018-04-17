class AddOptionsToDynamicModels < ActiveRecord::Migration
  def change
    add_column :dynamic_models, :options, :string
  end
end
