class AddTableKeyNameToDynamicModels < ActiveRecord::Migration
  def change
    add_column :dynamic_models, :table_key_name, :string
  end
end
