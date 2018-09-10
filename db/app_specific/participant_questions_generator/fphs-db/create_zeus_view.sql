/* Create a view that takes the {{app_schema}} ids and generates a Rails-friendly view in the ml_app schema

For development:

  \c fphs_demo
  create schema {{app_schema}};
  create table {{app_schema}}.tmbs (id serial, master_id integer);
  insert into {{app_schema}}.tmbs (master_id) (select id from ml_app.masters order by random());
  alter table ml_app.{{app_name}}_assignments rename to {{app_name}}_assignments_old;

  -- run the rest of the script

For production:

  Zeus must be upgraded to v6.0.21 at least to recognize the view.
  On Zeus, add the appropriate BHS External Identifier configuration.

  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  {{app_name}}_assignments	  BHS ID	{{app_name}}_id      false		      \d{1,9}	 true	         true	         0	  999999999


  On Elaine
  Name              label   attribute   alphanumeric  Pattern  Prevent edit  Pregenerate   min  max
  {{app_name}}_assignments	  BHS ID	{{app_name}}_id      false		      \d{1,9}	 false	       false         0	  999999999

*/

  create view ml_app.{{app_name}}_assignments as select id, master_id, id {{app_name}}_id, now() created_at, now() updated_at from {{app_schema}}.tmbs;

  GRANT ALL ON ml_app.{{app_name}}_assignments TO fphs;
  GRANT SELECT ON ml_app.{{app_name}}_assignments TO fphsusr;
  GRANT SELECT ON ml_app.{{app_name}}_assignments TO fphsetl;
  GRANT SELECT ON ml_app.{{app_name}}_assignments TO fphsadm;
