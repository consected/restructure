class CleanActivityLogDefs < ActiveRecord::Migration[6.1]
  def change
    ActivityLog.active.where(rec_type: '').update_all(rec_type: nil)
    ActivityLog.active.where(process_name: '').update_all(process_name: nil)
  end
end
