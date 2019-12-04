set search_path=grit, ml_app;

BEGIN;

  create view grit_subject_infos
    as
    select * from ml_app.player_infos;


  create view grit_subject_contacts
    as
    select * from ml_app.player_contacts;


  create view grit_subject_addresses
    as
    select * from ml_app.addresses;


COMMIT;
