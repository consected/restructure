/* Create a view that takes the persnet_schema ids and generates a Rails-friendly view in the ml_app schema

For development:

  \c fphs_demo
  create schema persnet_schema;
  create table persnet_schema.tmbs (id serial, master_id integer);
  insert into persnet_schema.tmbs (master_id) (select id from ml_app.masters order by random());
  alter table ml_app.persnet_assignments rename to persnet_assignments_old;

  -- run the rest of the script

For production:

  Zeus must be upgraded to v6.0.21 at least to recognize the view.
  On Zeus, add the appropriate BHS External Identifier configuration.

  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  persnet_assignments	  BHS ID	persnet_id      false		      \d{1,9}	 true	         true	         0	  999999999


  On Elaine
  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  persnet_assignments	  BHS ID	persnet_id      false		      \d{1,9}	 false	       false         0	  999999999

*/

  create view ml_app.persnet_assignments as select id, master_id, id persnet_id, now() created_at, now() updated_at from persnet_schema.tmbs;

  GRANT ALL ON ml_app.persnet_assignments TO fphs;
  GRANT SELECT ON ml_app.persnet_assignments TO fphsusr;
  GRANT SELECT ON ml_app.persnet_assignments TO fphsetl;
  GRANT SELECT ON ml_app.persnet_assignments TO fphsadm;
