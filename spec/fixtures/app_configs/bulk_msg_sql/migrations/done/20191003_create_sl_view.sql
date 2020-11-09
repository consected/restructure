set search_path=bulk_msg,ml_app;

      BEGIN;

create view short_links_by_list
as
select sl.*, mrdm.to_record_id list_id
from zeus_short_links sl
inner join model_references mrsched
on mrsched.to_record_type = 'ActivityLog::ZeusBulkMessage'
and sl.for_item_id = mrsched.to_record_id
and mrsched.from_record_type = 'ActivityLog::ZeusBulkMessage'
inner join model_references mrdm
on mrdm.from_record_type = 'ActivityLog::ZeusBulkMessage'
and mrdm.from_record_id = mrsched.from_record_id
and mrdm.to_record_type = 'DynamicModel::ZeusBulkMessage'
;

REVOKE ALL ON SCHEMA bulk_msg FROM fphs;
GRANT ALL ON SCHEMA bulk_msg TO fphs;
GRANT USAGE ON SCHEMA bulk_msg TO fphsadm;
GRANT USAGE ON SCHEMA bulk_msg TO fphsusr;
GRANT USAGE ON SCHEMA bulk_msg TO fphsetl;


GRANT ALL ON ALL TABLES IN SCHEMA bulk_msg TO fphs;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA bulk_msg TO fphsusr;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA bulk_msg TO fphsetl;
GRANT SELECT,INSERT,DELETE,TRUNCATE,UPDATE ON ALL TABLES IN SCHEMA bulk_msg TO fphsadm;

GRANT ALL ON ALL SEQUENCES IN SCHEMA bulk_msg TO fphs;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA bulk_msg TO fphsusr;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA bulk_msg TO fphsetl;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA bulk_msg TO fphsadm;


DO
$body$
BEGIN

IF EXISTS (
   SELECT *
   FROM   pg_catalog.pg_roles
   WHERE  rolname = 'fphsrailsapp') THEN

   GRANT USAGE ON SCHEMA bulk_msg TO fphsrailsapp;
   GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA bulk_msg TO fphsrailsapp;
   GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA bulk_msg TO fphsrailsapp;
END IF;


END
$body$;

commit;
