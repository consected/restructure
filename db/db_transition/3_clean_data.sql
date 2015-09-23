set SEARCH_PATH=ml_app;

update ml_app.player_infos set source = trim(source);

update ml_app.player_infos set source = 'NFLPA' where source is null;

update ml_app.player_infos set source = 'Other' where lower(source) in('unknown', 'usps');
update ml_app.player_infos set source = 'CIS' where source ~* 'cis.+' or lower(source) in('contactinfo', 'redcap');
update ml_app.player_infos set source = 'Integrate' where source ~* 'integrate.+';
update ml_app.player_infos set source = 'NFLPA' where source ~* 'nflpa.+';



update ml_app.player_contacts set rec_type = 'Phone' where rec_type = 'Paper' AND data ~ '\d{3}-\d{3}-\d{4}';

update ml_app.player_contacts set source = trim(source), rec_type = trim(rec_type);


update ml_app.player_contacts set source = 'Other' where source is null or lower(source) in('unknown', 'usps', 'd');
update ml_app.player_contacts set source = 'CIS' where source ~* 'cis.+' or lower(source) in('contactinfo', 'redcap');
update ml_app.player_contacts set source = 'Integrate' where source ~* 'integrate.+';
update ml_app.player_contacts set source = 'NFLPA' where source ~* 'nflpa.+';


update ml_app.addresses set country = 'us' where country is null;
update ml_app.addresses set rec_type = trim(initcap(rec_type)), source = trim(source);
update ml_app.addresses set rec_type = 'Home' where rec_type ~* 'hom';

update ml_app.addresses set source = 'Other' where source is null or lower(source) in('unknown', 'usps');
update ml_app.addresses set source = 'CIS' where source ~* 'cis.+' or lower(source) in('contactinfo', 'redcap');
update ml_app.addresses set source = 'Integrate' where source ~* 'integrate.+';
update ml_app.addresses set source = 'NFLPA' where source ~* 'nflpa.+';



update ml_app.addresses set street2 = null where street2 ~* 'null';
update ml_app.addresses set zip = '0'|| trim(zip)  where trim(zip) ~ '^\d{4,4}$';

