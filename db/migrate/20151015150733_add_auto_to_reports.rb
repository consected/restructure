class AddAutoToReports < ActiveRecord::Migration
  def change
    add_column :reports, :auto, :boolean
  end
end
