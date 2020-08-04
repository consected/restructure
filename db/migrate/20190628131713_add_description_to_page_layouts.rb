class AddDescriptionToPageLayouts < ActiveRecord::Migration[4.2]
  def change
    add_column :page_layouts, :description, :string
  end
end
