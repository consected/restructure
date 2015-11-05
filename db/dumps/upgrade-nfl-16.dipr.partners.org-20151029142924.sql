-- Script created @ 2015-10-29 14:29:24 -0400

set search_path=ml_app;
begin;

CREATE FUNCTION tracker_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            if (select EXISTS(
                    select 1 from trackers where 
                    protocol_id  = NEW.protocol_id AND 
                    master_id = NEW.master_id
                    )
                ) then
                UPDATE trackers SET
                    master_id = NEW.master_id, 
                    protocol_id = NEW.protocol_id, 
                    protocol_event_id = NEW.protocol_event_id, 
                    event_date = NEW.event_date, 
                    sub_process_id = NEW.sub_process_id, 
                    notes = NEW.notes, 
                    item_id = NEW.item_id, 
                    item_type = NEW.item_type,
                    -- do not update created_at --
                    updated_at = NEW.updated_at, 
                    user_id = NEW.user_id
                WHERE master_id = NEW.master_id AND 
                    protocol_id = NEW.protocol_id
                ;
                RETURN NULL;
            end if;
            RETURN NEW;
        END;
    $$;


CREATE TRIGGER tracker_upsert BEFORE INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE tracker_upsert();



CREATE TABLE "reports" ("id" serial primary key, "name" character varying, "primary_table" character varying, "description" character varying, "sql" character varying, "search_attrs" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_reports_on_admin_id" ON "reports"  ("admin_id");
ALTER TABLE "reports" ADD CONSTRAINT "fk_rails_b138baacff"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "reports" DROP "primary_table";
CREATE TABLE "external_links" ("id" serial primary key, "name" character varying, "value" character varying, "disabled" boolean, "admin_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_external_links_on_admin_id" ON "external_links"  ("admin_id");
ALTER TABLE "external_links" ADD CONSTRAINT "fk_rails_ebf3863277"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "reports" ADD "report_type" character varying;
ALTER TABLE "reports" ADD "auto" boolean;
ALTER TABLE "reports" ADD "searchable" boolean;
ALTER TABLE "reports" ADD "position" integer;
CREATE TABLE "sage_assignments" ("id" serial primary key, "sage_id" character varying(10), "assigned_by" character varying, "user_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_sage_assignments_on_user_id" ON "sage_assignments"  ("user_id");
ALTER TABLE "sage_assignments" ADD CONSTRAINT "fk_rails_971255ec2c"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE UNIQUE INDEX  "index_sage_assignments_on_sage_id" ON "sage_assignments"  ("sage_id");
ALTER TABLE "sage_assignments" ADD "master_id" integer;
CREATE  INDEX  "index_sage_assignments_on_master_id" ON "sage_assignments"  ("master_id");
ALTER TABLE "sage_assignments" ADD CONSTRAINT "fk_rails_ebab73db27"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "sage_assignments" ADD "admin_id" integer;
CREATE  INDEX  "index_sage_assignments_on_admin_id" ON "sage_assignments"  ("admin_id");
ALTER TABLE "sage_assignments" ADD CONSTRAINT "fk_rails_e3c559b547"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "masters" ADD "contact_id" integer;

update masters m set contact_id=(select contact_id from player_infos pi where pi.master_id = m.id);


CREATE TABLE "dynamic_models" ("id" serial primary key, "name" character varying, "table_name" character varying, "schema_name" character varying, "primary_key_name" character varying, "foreign_key_name" character varying, "description" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_dynamic_models_on_admin_id" ON "dynamic_models"  ("admin_id");
ALTER TABLE "dynamic_models" ADD CONSTRAINT "fk_rails_deec8fcb38"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "dynamic_models" ADD "position" integer;
ALTER TABLE "dynamic_models" ADD "category" character varying;
ALTER TABLE "dynamic_models" ADD "table_key_name" character varying;
ALTER TABLE "item_flags" ADD "disabled" boolean;
CREATE TABLE "user_authorizations" ("id" serial primary key, "user_id" integer, "has_authorization" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
ALTER TABLE "dynamic_models" ADD "field_list" character varying;
ALTER TABLE "dynamic_models" ADD "result_order" character varying;

insert into reports (name, sql, report_type, created_at, updated_at, description, disabled)
values ('Sage Assigned','select id, sage_id from sage_assignments where master_id is not null', 'regular_report', now(),now(), '', false),
('Sage Unassigned', 'select id, sage_id from sage_assignments where master_id is null', 'regular_report', now(),now(), '', false);



CREATE TABLE report_history (
    "id" integer not null, 
    "name" character varying,     
    "description" character varying, 
    "sql" character varying, 
    "search_attrs" character varying, 
    "admin_id" integer, 
    "disabled" boolean, 
    "report_type" character varying,
    "auto" boolean,
    "searchable" boolean,
    "position" integer,
    "created_at" timestamp NOT NULL, 
    "updated_at" timestamp NOT NULL,    
    report_id integer
);

CREATE SEQUENCE report_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE report_history_id_seq OWNED BY report_history.id;
ALTER TABLE ONLY report_history ALTER COLUMN id SET DEFAULT nextval('report_history_id_seq'::regclass);
ALTER TABLE ONLY report_history ADD CONSTRAINT report_history_pkey PRIMARY KEY (id);

CREATE INDEX index_report_history_on_report_id ON report_history USING btree (report_id);

ALTER TABLE ONLY report_history ADD CONSTRAINT fk_report_history_reports FOREIGN KEY (report_id) REFERENCES reports(id);

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
                    updated_at
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
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER report_history_insert AFTER INSERT ON reports FOR EACH ROW EXECUTE PROCEDURE log_report_update();
CREATE TRIGGER report_history_update AFTER UPDATE ON reports FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_report_update();



CREATE TABLE user_authorization_history (
    "id" integer not null, 
    "user_id" character varying,     
    "has_authorization" character varying, 
    "admin_id" integer, 
    "disabled" boolean, 
    "created_at" timestamp NOT NULL, 
    "updated_at" timestamp NOT NULL,    
    user_authorization_id integer
);

CREATE SEQUENCE user_authorization_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE user_authorization_history_id_seq OWNED BY user_authorization_history.id;
ALTER TABLE ONLY user_authorization_history ALTER COLUMN id SET DEFAULT nextval('user_authorization_history_id_seq'::regclass);
ALTER TABLE ONLY user_authorization_history ADD CONSTRAINT user_authorization_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_authorization_history_on_user_authorization_id ON user_authorization_history USING btree (user_authorization_id);

ALTER TABLE ONLY user_authorization_history ADD CONSTRAINT fk_user_authorization_history_user_authorizations FOREIGN KEY (user_authorization_id) REFERENCES user_authorizations(id);

CREATE FUNCTION log_user_authorization_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_authorization_history
            (
                    user_authorization_id,
                    user_id,                    
                    has_authorization,                    
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.user_id,                
                NEW.has_authorization,               
                NEW.admin_id,                
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER user_authorization_history_insert AFTER INSERT ON user_authorizations FOR EACH ROW EXECUTE PROCEDURE log_user_authorization_update();
CREATE TRIGGER user_authorization_history_update AFTER UPDATE ON user_authorizations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_authorization_update();


CREATE TABLE dynamic_model_history (
    "id" integer not null, 
    "name" character varying,     
    "table_name" character varying, 
    "schema_name" character varying, 
    "primary_key_name" character varying, 
    "foreign_key_name" character varying, 
    "description" character varying,     
    "admin_id" integer, 
    "disabled" boolean, 
    "position" integer,
    "category" character varying,     
    "table_key_name" character varying,     
    "field_list" character varying,     
    "result_order" character varying,     
    "created_at" timestamp NOT NULL, 
    "updated_at" timestamp NOT NULL,    
    dynamic_model_id integer
);

CREATE SEQUENCE dynamic_model_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dynamic_model_history_id_seq OWNED BY dynamic_model_history.id;
ALTER TABLE ONLY dynamic_model_history ALTER COLUMN id SET DEFAULT nextval('dynamic_model_history_id_seq'::regclass);
ALTER TABLE ONLY dynamic_model_history ADD CONSTRAINT dynamic_model_history_pkey PRIMARY KEY (id);

CREATE INDEX index_dynamic_model_history_on_dynamic_model_id ON dynamic_model_history USING btree (dynamic_model_id);

ALTER TABLE ONLY dynamic_model_history ADD CONSTRAINT fk_dynamic_model_history_dynamic_models FOREIGN KEY (dynamic_model_id) REFERENCES dynamic_models(id);

CREATE FUNCTION log_dynamic_model_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO dynamic_model_history
            (
                    dynamic_model_id,
                    name,                    
                    table_name, 
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order
                    
                    
                )                 
            SELECT                 
                NEW.id,
                                    NEW.name,    
                    NEW.table_name, 
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER dynamic_model_history_insert AFTER INSERT ON dynamic_models FOR EACH ROW EXECUTE PROCEDURE log_dynamic_model_update();
CREATE TRIGGER dynamic_model_history_update AFTER UPDATE ON dynamic_models FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_dynamic_model_update();


CREATE TABLE external_link_history (
   "id" integer not null, 
    "name" character varying,     
    "value" character varying,     
    "admin_id" integer,
    "disabled" boolean,     
    "created_at" timestamp NOT NULL, 
    "updated_at" timestamp NOT NULL,    
    external_link_id integer
);

CREATE SEQUENCE external_link_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE external_link_history_id_seq OWNED BY external_link_history.id;
ALTER TABLE ONLY external_link_history ALTER COLUMN id SET DEFAULT nextval('external_link_history_id_seq'::regclass);
ALTER TABLE ONLY external_link_history ADD CONSTRAINT external_link_history_pkey PRIMARY KEY (id);

CREATE INDEX index_external_link_history_on_external_link_id ON external_link_history USING btree (external_link_id);

ALTER TABLE ONLY external_link_history ADD CONSTRAINT fk_external_link_history_external_links FOREIGN KEY (external_link_id) REFERENCES external_links(id);

CREATE FUNCTION log_external_link_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO external_link_history
            (
                    external_link_id,                    
                    name,                    
                    value,
                    admin_id,
                    disabled,                    
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.name,    
                    NEW.value,                     
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER external_link_history_insert AFTER INSERT ON external_links FOR EACH ROW EXECUTE PROCEDURE log_external_link_update();
CREATE TRIGGER external_link_history_update AFTER UPDATE ON external_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_link_update();

alter table item_flag_history add column disabled boolean;

drop FUNCTION log_item_flag_update() cascade;

CREATE FUNCTION log_item_flag_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_history
            (
                    item_flag_id,
                    item_id ,
                    item_type,
                    item_flag_name_id,
                    created_at ,
                    updated_at ,
                    user_id ,
                    disabled
                )                 
            SELECT                 
                NEW.id,
                NEW.item_id ,
                    NEW.item_type,
                    NEW.item_flag_name_id,
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.user_id ,
                    NEW.disabled
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON item_flags FOR EACH ROW EXECUTE PROCEDURE log_item_flag_update();
CREATE TRIGGER item_flag_history_update AFTER UPDATE ON item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_update();


select * from ml_work.playercareerdata_update into ml_app.player_career_data;
update player_career_data set draftedbyteam=null where draftedbyteam = 'NULL';
update player_career_data set teamhistory=null where teamhistory = 'NULL';
update player_career_data set college=null where college = 'NULL';

select * from ml_work.playertransactions_update into ml_app.player_transactions;
update player_transactions set transactionhistoricalteamname = null where  transactionhistoricalteamname = 'NULL';
update player_transactions set transactioncurrentteamname = null where  transactioncurrentteamname = 'NULL';

select * from ml_work.teamhistoryfromcontracts_update into ml_app.team_history;
select * from ml_work.playerseverancedate_update into ml_app.player_severance;

select * from ml_work.profootball_master into ml_app.pro_football_master;

end;




  