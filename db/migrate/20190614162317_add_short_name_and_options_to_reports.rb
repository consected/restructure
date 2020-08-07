class AddShortNameAndOptionsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :short_name, :string
    add_column :reports, :options, :string
  end
end
