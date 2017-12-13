-- Script created @ 2017-12-13 10:40:59 +0000
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
ALTER TABLE "activity_logs" ADD "field_list" character varying;
ALTER TABLE "activity_logs" ADD "blank_log_field_list" character varying;
ALTER TABLE "activity_log_history" ADD "action_when_attribute" character varying;
ALTER TABLE "activity_log_history" ADD "field_list" character varying;
ALTER TABLE "activity_log_history" ADD "blank_log_field_list" character varying;

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
                        disabled,
                        action_when_attribute,
                        field_list,
                        blank_log_field_list
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.item_type,
                        NEW.rec_type,
                        NEW.disabled,
                        NEW.action_when_attribute,
                        NEW.field_list,
                        NEW.blank_log_field_list
                    ;
                    RETURN NEW;
                END;
            $$;
            CREATE TRIGGER activity_log_history_insert AFTER INSERT ON activity_logs FOR EACH ROW EXECUTE PROCEDURE log_activity_log_update();
            CREATE TRIGGER activity_log_history_update AFTER UPDATE ON activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_update();

;
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
CREATE TABLE "external_identifier_history" ("id" serial primary key, "name" character varying, "label" character varying, "external_id_attribute" character varying, "external_id_view_formatter" character varying, "external_id_edit_pattern" character varying, "prevent_edit" boolean, "pregenerate_ids" boolean, "min_id" bigint, "max_id" bigint, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL, "external_identifier_id" integer) ;
CREATE  INDEX  "index_external_identifier_history_on_admin_id" ON "external_identifier_history"  ("admin_id");
CREATE  INDEX  "index_external_identifier_history_on_external_identifier_id" ON "external_identifier_history"  ("external_identifier_id");
ALTER TABLE "external_identifier_history" ADD CONSTRAINT "fk_rails_5b0628cf42"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "external_identifier_history" ADD CONSTRAINT "fk_rails_0210618434"
FOREIGN KEY ("external_identifier_id")
  REFERENCES "external_identifiers" ("id")
;

        DROP TRIGGER IF EXISTS external_identifier_history_insert on external_identifiers;
        DROP TRIGGER IF EXISTS external_identifier_history_update on external_identifiers;
        DROP FUNCTION IF EXISTS log_external_identifier_update();
        CREATE FUNCTION log_external_identifier_update() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
                BEGIN
                    INSERT INTO external_identifier_history
                    (
                        name,
                        external_identifier_id,
                        label,
                        external_id_attribute,
                        external_id_view_formatter,
                        external_id_edit_pattern,
                        prevent_edit,
                        pregenerate_ids,
                        min_id,
                        max_id,
                        admin_id,
                        created_at,
                        updated_at,
                        disabled
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.label,
                        NEW.external_id_attribute,
                        NEW.external_id_view_formatter,
                        NEW.external_id_edit_pattern,
                        NEW.prevent_edit,
                        NEW.pregenerate_ids,
                        NEW.min_id,
                        NEW.max_id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;
            CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON external_identifiers FOR EACH ROW EXECUTE PROCEDURE log_external_identifier_update();
            CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_identifier_update();

;


    CREATE TABLE activity_log_player_contact_phone_history (
        id integer NOT NULL,
        master_id integer,
        player_contact_id integer,
        data varchar,
        select_call_direction varchar,
        select_who varchar,
        called_when date,
        select_result varchar,
        select_next_step varchar,
        follow_up_when date,
        notes varchar,
        protocol_id integer,
        set_related_player_contact_rank varchar,
        user_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        activity_log_player_contact_phone_id integer
    );

    CREATE FUNCTION log_activity_log_player_contact_phone_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO activity_log_player_contact_phone_history
                (
                    master_id,
                    player_contact_id,
                    data,
                    select_call_direction,
                    select_who,
                    called_when,
                    select_result,
                    select_next_step,
                    follow_up_when,
                    notes,
                    protocol_id,
                    set_related_player_contact_rank,
                    user_id,
                    created_at,
                    updated_at,
                    activity_log_player_contact_phone_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.player_contact_id,
                    NEW.data,
                    NEW.select_call_direction,
                    NEW.select_who,
                    NEW.called_when,
                    NEW.select_result,
                    NEW.select_next_step,
                    NEW.follow_up_when,
                    NEW.notes,
                    NEW.protocol_id,
                    NEW.set_related_player_contact_rank,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

    CREATE SEQUENCE activity_log_player_contact_phone_history_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

    ALTER SEQUENCE activity_log_player_contact_phone_history_id_seq OWNED BY activity_log_player_contact_phone_history.id;

    ALTER TABLE ONLY activity_log_player_contact_phone_history ALTER COLUMN id SET DEFAULT nextval('activity_log_player_contact_phone_history_id_seq'::regclass);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT activity_log_player_contact_phone_history_pkey PRIMARY KEY (id);

    CREATE INDEX index_activity_log_player_contact_phone_history_on_master_id ON activity_log_player_contact_phone_history USING btree (master_id);
    CREATE INDEX index_activity_log_player_contact_phone_history_on_player_contact_phone_id ON activity_log_player_contact_phone_history USING btree (player_contact_id);

    CREATE INDEX index_activity_log_player_contact_phone_history_on_activity_log_player_contact_phone_id ON activity_log_player_contact_phone_history USING btree (activity_log_player_contact_phone_id);
    CREATE INDEX index_activity_log_player_contact_phone_history_on_user_id ON activity_log_player_contact_phone_history USING btree (user_id);

    CREATE TRIGGER activity_log_player_contact_phone_history_insert AFTER INSERT ON activity_log_player_contact_phones FOR EACH ROW EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();
    CREATE TRIGGER activity_log_player_contact_phone_history_update AFTER UPDATE ON activity_log_player_contact_phones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_player_contact_phone_update();

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_users FOREIGN KEY (user_id) REFERENCES users(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_player_contact_phone_id FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);

    ALTER TABLE ONLY activity_log_player_contact_phone_history
        ADD CONSTRAINT fk_activity_log_player_contact_phone_history_activity_log_player_contact_phones FOREIGN KEY (activity_log_player_contact_phone_id) REFERENCES activity_log_player_contact_phones(id);

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
20171013141837
20171025095942
20171031145807
20171207163040
20171207170748
\.

 commit; ;
