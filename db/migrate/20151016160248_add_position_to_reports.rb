class AddPositionToReports < ActiveRecord::Migration
  def change
    add_column :reports, :position, :integer
  end
end
