-- Script created @ 2015-10-21 12:23:39 -0400
begin;
set search_path = ml_app;

ALTER TABLE "masters" ADD "contact_id" integer;
update masters m set contact_id=(select contact_id from player_infos pi where pi.master_id = m.id);

commit;
