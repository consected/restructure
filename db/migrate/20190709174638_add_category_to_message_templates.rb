class AddCategoryToMessageTemplates < ActiveRecord::Migration
  def change
    add_column :message_templates, :category, :string
  end
end
