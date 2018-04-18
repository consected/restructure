/* Create a view that takes the testmybrain ids and generates a Rails-friendly view in the ml_app schema

For development:

  \c fphs_demo
  create schema testmybrain;
  create table testmybrain.tmbs (id serial, master_id integer);
  insert into testmybrain.tmbs (master_id) (select id from ml_app.masters order by random());
  alter table ml_app.bhs_assignments rename to bhs_assignments_old;

  -- run the rest of the script

For production:

  Zeus must be upgraded to v6.0.21 at least to recognize the view.
  On Zeus, add the appropriate BHS External Identifier configuration.

  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  bhs_assignments	  BHS ID	bhs_id      false		      \d{1,9}	 true	         true	         0	  999999999


  On Elaine
  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  bhs_assignments	  BHS ID	bhs_id      false		      \d{1,9}	 false	       false         0	  999999999

*/

  create view ml_app.bhs_assignments as select id, master_id, id bhs_id, now() created_at, now() updated_at from testmybrain.tmbs;

  GRANT ALL ON ml_app.bhs_assignments TO fphs;
  GRANT SELECT ON ml_app.bhs_assignments TO fphsusr;
  GRANT SELECT ON ml_app.bhs_assignments TO fphsetl;
  GRANT SELECT ON ml_app.bhs_assignments TO fphsadm;
