class AddShortNameAndOptionsToReports < ActiveRecord::Migration[4.2]
  def change
    add_column :reports, :short_name, :string
    add_column :reports, :options, :string
  end
end
