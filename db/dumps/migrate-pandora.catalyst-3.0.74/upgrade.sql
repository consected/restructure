-- Script created @ 2016-01-13 17:18:12 -0500
set search_path=public; 
 begin;  ;
ALTER TABLE "reports" ADD "item_type" character varying;
ALTER TABLE "report_history" ADD "item_type" character varying;
ALTER TABLE "report_history" ADD "edit_model" character varying;
ALTER TABLE "report_history" ADD "edit_field_names" character varying;
ALTER TABLE "report_history" ADD "selection_fields" character varying;

DROP TRIGGER report_history_insert ON reports;
DROP TRIGGER report_history_update ON reports;
DROP FUNCTION log_report_update();
CREATE FUNCTION log_report_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO report_history
            (
                    report_id,
                    name,                    
                    description,
                    sql,
                    search_attrs,
                    admin_id,
                    disabled,
                    report_type,
                    auto,
                    searchable,
                    position,
                    created_at,
                    updated_at,
                    edit_field_names,
                    selection_fields,
                    item_type
                )                 
            SELECT                 
                NEW.id,
                NEW.name,                
                NEW.description,
                NEW.sql,
                NEW.search_attrs,
                NEW.admin_id,                
                NEW.disabled,
                NEW.report_type,
                NEW.auto,
                NEW.searchable,
                NEW.position,                
                NEW.created_at,
                NEW.updated_at,
                NEW.edit_field_names,
                NEW.selection_fields,
                NEW.item_type
            ;
            RETURN NEW;
        END;
    $$;


    
CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();
CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();


;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO fphs;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA public TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fphs;
SET search_path = public, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20151218203119
\.

 commit; ;
