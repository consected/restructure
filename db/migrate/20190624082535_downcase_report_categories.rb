# Migration version added
class DowncaseReportCategories < ActiveRecord::Migration[4.2]
  def change
    auto_admin = Admin.active.first

    Report.active.each do |r|
      r.item_type = r.item_type.downcase if r.item_type
      r.current_admin = auto_admin
      r.save!
    end
  end
end
