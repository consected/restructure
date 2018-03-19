drop function if exists ml_app.demo_sync_bhs_record() cascade;

create function ml_app.demo_sync_bhs_record() returns trigger
LANGUAGE plpgsql
AS $$
DECLARE
	prev_master_id integer;
	found_player_info record;
	found_synced record;
	found_bhs record;
begin


select *
into found_synced
from player_infos pi
where pi.master_id = new.master_id;

IF FOUND THEN
  return NEW;
END IF;

select *
into found_bhs
from bhs_assignments bhs
where bhs.id = new.bhs_assignment_id
limit 1;

select *
into found_player_info
from player_infos pi
left join bhs_assignments b on b.master_id = pi.master_id
where bhs_id is null
order by pi.id asc
limit 1;


IF NOT FOUND THEN
	RAISE EXCEPTION 'No empty BHS ID found --> %', (bhs_id);
ELSE
	update player_infos
	set master_id = new.master_id, death_date = null
	where id = found_player_info.id;

	update player_contacts
	set master_id = new.master_id
	where id = found_player_info.id;

	update activity_log_bhs_assignments
	set select_record_from_player_contact_phones = (
		select data from player_contacts
		where rec_type='phone' AND rank is not null AND master_id = new.master_id
		order by rank desc
		limit 1
	), results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar)
	where bhs_assignment_id is not null AND (select_record_from_player_contact_phones is null or select_record_from_player_contact_phones = '');


	return new;
END IF;
end;

$$;


CREATE TRIGGER demo_sync_bhs_update AFTER INSERT ON ml_app.activity_log_bhs_assignments FOR EACH ROW EXECUTE PROCEDURE ml_app.demo_sync_bhs_record();
