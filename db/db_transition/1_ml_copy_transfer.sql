set search_path = ml_app,ml_work,q1;

---Set back addresses ----------------------
truncate table ml_app.addresses cascade;
alter sequence addresses_id_seq start with 1;
alter sequence address_history_id_seq start with 1;

---Set back player_contacts ----------------------
truncate table ml_app.player_contacts cascade;
alter sequence player_contacts_id_seq start with 1;
alter sequence player_contacts_history_id_seq start with 1;

---Set back addresses ----------------------
truncate table ml_app.player_infos cascade;
alter sequence player_infos_id_seq start with 1;
alter sequence player_infos_history_id_seq start with 1;

---Set back masters ----------------------
truncate table ml_app.masters cascade;
alter sequence masters_id_seq start with 1;


/* Create the master list of msids - note this picks only the distinct msid entries,*/
insert into ml_app.masters (msid, pro_id) select distinct msid, pro_id from ml_work.ml_copy;

-- Populate addresses from ml_work.address
insert into ml_app.addresses ( master_id,street,street2,city,state,zip,rec_type,source,rank,country,created_at,updated_at, user_id)
select a.id,b.street,b.street2,b.city,b.state,b.zip,b.type,b.source,b.rank,'us',now(),b.lastmod, ut.user_id
from ml_app.masters a
inner join ml_work.address b 
on a.msid = b.msid
left outer join user_translation ut
on ut.orig_username = b.changedby
;

--Populate player_contacts from playercontact
insert into ml_app.player_contacts ( master_id,rec_type,data,source,rank,created_at,updated_at)
select a.id,b.pctype,b.pcdata,b.source,b.rank,now(),b.lastmod
from ml_app.masters a
inner join ml_work.playercontact b 
on a.msid = b.msid
;

--Populate player_infos from ml_copy
insert into ml_app.player_infos (master_id,first_name,last_name,middle_name,nick_name,
birth_date,death_date,created_at,updated_at,contact_pref,start_year,rank,notes,contact_id,
college,source )
select a.id,b.first_name,b.last_name,b.middle_name,b.nick_name,
b.birthdate,b.pro_dod,now(),b.lastmod,b.cprefs,b.startyear,b.accuracy_score,
b.notes,b.contactid,b.pro_college,b.source
from ml_app.masters a
inner join ml_work.ml_copy b 
on a.msid = b.msid
;
--Populate pro_infos from ml_copy
--
insert into ml_app.pro_infos (master_id,pro_id,first_name,last_name,middle_name,nick_name,
birth_date,death_date,start_year,end_year,college,birthplace,created_at,updated_at)
select a.id,b.pro_id,b.pro_first_name,b.pro_last_name,b.pro_middle_name,b.pro_nick_name,
b.pro_dob,b.pro_dod,b.pro_start_year,b.pro_end_year,lower(b.pro_college),lower(b.pro_birthplace),now(),b.lastmod
from ml_app.masters a
inner join ml_work.ml_copy b 
on a.msid = b.msid
;
--Populate scantrons from scantron
--Needs null fields default....
insert into ml_app.scantrons ( master_id,scantron_id,created_at,updated_at)
select a.id,b.scantronid,now(),now()
from ml_app.masters a
inner join ml_work.scantron b 
on a.msid = b.msid
;
