drop function if exists ml_app.create_remote_bhs_record(bhs_id integer, new_player_info_record player_infos, new_player_contact_records player_contacts[]) cascade;

-- Run tests with
-- select ml_app.create_remote_bhs_record(364648868, (select pi from player_infos pi where master_id = 105029 limit 1), '{}' );
create function ml_app.create_remote_bhs_record(match_bhs_id INTEGER, new_player_info_record player_infos, new_player_contact_records player_contacts[]) returns INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	found_bhs record;
begin

-- Find the bhs_assignments external identifier record for this master record and
-- validate that it exists
select *
into found_bhs
from bhs_assignments bhs
where bhs.bhs_id = match_bhs_id
limit 1;



IF NOT FOUND THEN
	RAISE EXCEPTION 'No BHS ID found for master_id --> %', (new_player_info_record.master_id);
ELSE


  INSERT INTO player_infos
  (
    master_id,
    first_name,
    last_name,
    middle_name,
    nick_name,
    birth_date,
    death_date,
    user_id,
    created_at,
    updated_at,
    contact_pref,
    start_year,
    rank,
    notes,
    contact_id,
    college,
    end_year,
    source
  )
  SELECT
    found_bhs.master_id,
    new_player_info_record.first_name,
    new_player_info_record.last_name,
    new_player_info_record.middle_name,
    new_player_info_record.nick_name,
    new_player_info_record.birth_date,
    new_player_info_record.death_date,
    new_player_info_record.user_id,
    new_player_info_record.created_at,
    new_player_info_record.updated_at,
    new_player_info_record.contact_pref,
    new_player_info_record.start_year,
    new_player_info_record.rank,
    new_player_info_record.notes,
    new_player_info_record.contact_id,
    new_player_info_record.college,
    new_player_info_record.end_year,
    new_player_info_record.source
  ;

	-- update player_contacts
	-- set master_id = new_player_info_record.master_id
	-- where id = found_player_info.id;
  --
	update activity_log_bhs_assignments
	set select_record_from_player_contact_phones = (
		select data from player_contacts
		where rec_type='phone' AND rank is not null AND master_id = new_player_info_record.master_id
		order by rank desc
		limit 1
	), results_link = ('https://testmybrain.org?demotestid=' || found_bhs.bhs_id::varchar)
	where bhs_assignment_id is not null AND (select_record_from_player_contact_phones is null or select_record_from_player_contact_phones = '');


	return found_bhs.master_id;
END IF;
end;

$$;
