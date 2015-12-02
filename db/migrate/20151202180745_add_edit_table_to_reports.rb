class AddEditTableToReports < ActiveRecord::Migration
  def change
    add_column :reports, :edit_model, :string
    add_column :reports, :edit_field_names, :string
  end
end
