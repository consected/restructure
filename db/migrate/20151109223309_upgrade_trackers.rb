class UpgradeTrackers < ActiveRecord::Migration
  def change
    execute <<EOF
alter table trackers rename to trackers_original;    
create view trackers as select distinct on (master_id, protocol_id) id, master_id, protocol_id, event_date, user_id, created_at, updated_at, notes, sub_process_id, protocol_event_id, item_id, item_type from tracker_history order by master_id, protocol_id, event_date desc nulls last, updated_at desc nulls last;
update tracker_history set tracker_id = id;

-- reset the foreign keys pointing to tracker.
-- handle the inserts into tracker
-- update the trackers upsert trigger 

-- also need constraints

EOF
  end
end
