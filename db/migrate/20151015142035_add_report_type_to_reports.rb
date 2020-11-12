class AddReportTypeToReports < ActiveRecord::Migration
  def change
    add_column :reports, :report_type, :string
  end
end
