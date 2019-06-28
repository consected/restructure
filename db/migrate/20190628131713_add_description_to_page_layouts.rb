class AddDescriptionToPageLayouts < ActiveRecord::Migration
  def change
    add_column :page_layouts, :description, :string
  end
end
