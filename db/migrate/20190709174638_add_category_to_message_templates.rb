class AddCategoryToMessageTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :message_templates, :category, :string
  end
end
