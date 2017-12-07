-- Script created @ 2017-12-07 15:33:16 +0000
set search_path=ml_app; 
 begin;  ;
    
  DROP TRIGGER IF EXISTS address_update on addresses;
  DROP TRIGGER IF EXISTS address_insert on addresses;
  DROP FUNCTION IF EXISTS handle_address_update();
  CREATE FUNCTION handle_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          
          NEW.street := lower(NEW.street);
          NEW.street2 := lower(NEW.street2);
          NEW.street3 := lower(NEW.street3);
          NEW.city := lower(NEW.city);
          NEW.state := lower(NEW.state);
          NEW.zip := lower(NEW.zip);
          NEW.country := lower(NEW.country);
          NEW.postal_code := lower(NEW.postal_code);
          NEW.region := lower(NEW.region);
          NEW.source := lower(NEW.source);
          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER address_update BEFORE UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_address_update();
    CREATE TRIGGER address_insert BEFORE INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE handle_address_update();


  DROP FUNCTION IF EXISTS update_address_ranks(set_master_id INTEGER);
  CREATE FUNCTION update_address_ranks(set_master_id INTEGER) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM addresses
          WHERE master_id = set_master_id
          AND rank = 10
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE addresses SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;



;
    
  DROP TRIGGER IF EXISTS player_contact_update on player_contacts;
  DROP TRIGGER IF EXISTS player_contact_insert on player_contacts;
  DROP FUNCTION IF EXISTS handle_player_contact_update();
  CREATE FUNCTION handle_player_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
         

          NEW.rec_type := lower(NEW.rec_type);
          NEW.data := lower(NEW.data);
          NEW.source := lower(NEW.source);


          RETURN NEW;
            
        END;   
    $$;
    
    CREATE TRIGGER player_contact_update BEFORE UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE handle_player_contact_update();
    CREATE TRIGGER player_contact_insert BEFORE INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE handle_player_contact_update();



  DROP FUNCTION IF EXISTS update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR);
  CREATE FUNCTION update_player_contact_ranks(set_master_id INTEGER, set_rec_type VARCHAR) RETURNS INTEGER
    LANGUAGE plpgsql
    AS $$
        DECLARE
          latest_primary RECORD;
        BEGIN
  
          SELECT * into latest_primary 
          FROM player_contacts
          WHERE master_id = set_master_id
          AND rank = 10
          AND rec_type = set_rec_type
          ORDER BY updated_at DESC
          LIMIT 1;
        
          IF NOT FOUND THEN
            RETURN NULL;
          END IF;

          
          UPDATE player_contacts SET rank = 5 
          WHERE 
            master_id = set_master_id 
            AND rank = 10
            AND rec_type = set_rec_type
            AND id <> latest_primary.id;
          

          RETURN 1;
        END;
    $$;

;
CREATE TABLE "activity_logs" ("id" serial primary key, "name" character varying, "item_type" character varying, "rec_type" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE TABLE "activity_log_player_contact_phones" ("id" serial primary key, "data" character varying, "select_call_direction" character varying, "select_who" character varying, "called_when" date, "select_result" character varying, "select_next_step" character varying, "follow_up_when" date, "protocol_id" integer, "notes" character varying, "user_id" integer, "player_contact_id" integer, "master_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_activity_log_player_contact_phones_on_protocol_id" ON "activity_log_player_contact_phones"  ("protocol_id");
CREATE  INDEX  "index_activity_log_player_contact_phones_on_user_id" ON "activity_log_player_contact_phones"  ("user_id");
CREATE  INDEX  "index_activity_log_player_contact_phones_on_player_contact_id" ON "activity_log_player_contact_phones"  ("player_contact_id");
CREATE  INDEX  "index_activity_log_player_contact_phones_on_master_id" ON "activity_log_player_contact_phones"  ("master_id");
ALTER TABLE "activity_log_player_contact_phones" ADD CONSTRAINT "fk_rails_1d67a3e7f2"
FOREIGN KEY ("protocol_id")
  REFERENCES "protocols" ("id")
;
ALTER TABLE "activity_log_player_contact_phones" ADD CONSTRAINT "fk_rails_5ce1857310"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "activity_log_player_contact_phones" ADD CONSTRAINT "fk_rails_b071294797"
FOREIGN KEY ("player_contact_id")
  REFERENCES "player_contacts" ("id")
;
ALTER TABLE "activity_log_player_contact_phones" ADD CONSTRAINT "fk_rails_2de1cadfad"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "activity_logs" ADD "action_when_attribute" character varying;
ALTER TABLE "activity_log_player_contact_phones" ADD "set_related_player_contact_rank" character varying;
CREATE TABLE "activity_log_history" ("id" serial primary key, "activity_log_id" integer, "name" character varying, "item_type" character varying, "rec_type" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_activity_log_history_on_activity_log_id" ON "activity_log_history"  ("activity_log_id");
ALTER TABLE "activity_log_history" ADD CONSTRAINT "fk_rails_16d57266f7"
FOREIGN KEY ("activity_log_id")
  REFERENCES "activity_logs" ("id")
;

        DROP TRIGGER IF EXISTS activity_log_history_insert on activity_logs;
        DROP TRIGGER IF EXISTS activity_log_history_update on activity_logs;
        DROP FUNCTION IF EXISTS log_activity_log_update();
        CREATE FUNCTION log_activity_log_update() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
                BEGIN
                    INSERT INTO activity_log_history
                    (
                        name,
                        activity_log_id,
                        admin_id,
                        created_at,
                        updated_at,
                        item_type,
                        rec_type,
                        disabled
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.item_type,
                        NEW.rec_type,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;
            CREATE TRIGGER activity_log_history_insert AFTER INSERT ON activity_logs FOR EACH ROW EXECUTE PROCEDURE log_activity_log_update();
            CREATE TRIGGER activity_log_history_update AFTER UPDATE ON activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_update();

;
ALTER TABLE "activity_logs" ADD "field_list" character varying;
ALTER TABLE "activity_logs" ADD "blank_log_field_list" character varying;
CREATE TABLE "imports" ("id" serial primary key, "primary_table" character varying, "item_count" integer, "filename" character varying, "imported_items" integer[], "user_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_imports_on_user_id" ON "imports"  ("user_id");
ALTER TABLE "imports" ADD CONSTRAINT "fk_rails_b1e2154c26"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE TABLE "external_identifiers" ("id" serial primary key, "name" character varying, "label" character varying, "external_id_attribute" character varying, "external_id_view_formatter" character varying, "external_id_edit_pattern" character varying, "prevent_edit" boolean, "pregenerate_ids" boolean, "min_id" bigint, "max_id" bigint, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_external_identifiers_on_admin_id" ON "external_identifiers"  ("admin_id");
ALTER TABLE "external_identifiers" ADD CONSTRAINT "fk_rails_7218113eac"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20160210200918
20160210200919
20170823145313
20170901152707
20170908074038
20170922182052
20170926144234
20171002120537
20171013141835
20171025095942
20171031145807
\.

 commit; ;
