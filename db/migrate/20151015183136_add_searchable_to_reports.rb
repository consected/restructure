class AddSearchableToReports < ActiveRecord::Migration
  def change
    add_column :reports, :searchable, :boolean
  end
end
