class RemovePrimaryTableFromReports < ActiveRecord::Migration
  def change
    remove_column :reports, :primary_table, :string
  end
end
