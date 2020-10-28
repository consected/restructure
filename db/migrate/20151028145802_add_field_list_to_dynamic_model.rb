class AddFieldListToDynamicModel < ActiveRecord::Migration
  def change
    add_column :dynamic_models, :field_list, :string
  end
end
