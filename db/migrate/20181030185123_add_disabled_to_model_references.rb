class AddDisabledToModelReferences < ActiveRecord::Migration
  def change
    add_column :model_references, :disabled, :boolean
  end
end
