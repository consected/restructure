class AddSelectionFieldsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :selection_fields, :string
  end
end
