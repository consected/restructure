-- Script created @ 2019-07-17 16:28:43 +0100
set search_path=ml_app; 
 begin;  ;
ALTER TABLE "user_access_controls" ADD "role_name" character varying;
CREATE TABLE "exception_logs" ("id" serial primary key, "message" character varying, "main" character varying, "backtrace" character varying, "user_id" integer, "admin_id" integer, "notified_at" timestamp, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_exception_logs_on_user_id" ON "exception_logs"  ("user_id");
CREATE  INDEX  "index_exception_logs_on_admin_id" ON "exception_logs"  ("admin_id");
ALTER TABLE "exception_logs" ADD CONSTRAINT "fk_rails_c720bf523c"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "exception_logs" ADD CONSTRAINT "fk_rails_51ae125c4f"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
CREATE TABLE "nfs_store_containers" ("id" serial primary key, "name" character varying, "user_id" integer, "app_type_id" integer, "nfs_store_container_id" integer) ;
CREATE  INDEX  "index_nfs_store_containers_on_nfs_store_container_id" ON "nfs_store_containers"  ("nfs_store_container_id");
ALTER TABLE "nfs_store_containers" ADD CONSTRAINT "fk_rails_e01d928507"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_containers" ADD CONSTRAINT "fk_rails_6a3d7bf39f"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "nfs_store_containers" ADD CONSTRAINT "fk_rails_0c84487284"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
CREATE TABLE "nfs_store_uploads" ("id" serial primary key, "file_hash" character varying NOT NULL, "file_name" character varying NOT NULL, "content_type" character varying NOT NULL, "file_size" bigint NOT NULL, "chunk_count" integer, "completed" boolean, "file_updated_at" timestamp, "user_id" integer, "nfs_store_container_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
ALTER TABLE "nfs_store_uploads" ADD CONSTRAINT "fk_rails_bdb308087e"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_uploads" ADD CONSTRAINT "fk_rails_3f5167a964"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
CREATE TABLE "nfs_store_stored_files" ("id" serial primary key, "file_hash" character varying NOT NULL, "file_name" character varying NOT NULL, "content_type" character varying NOT NULL, "file_size" bigint NOT NULL, "path" character varying, "file_updated_at" timestamp, "user_id" integer, "nfs_store_container_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
CREATE  INDEX  "index_nfs_store_stored_files_on_nfs_store_container_id" ON "nfs_store_stored_files"  ("nfs_store_container_id");
ALTER TABLE "nfs_store_stored_files" ADD CONSTRAINT "fk_rails_1cc4562569"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_stored_files" ADD CONSTRAINT "fk_rails_0de144234e"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
CREATE TABLE "nfs_store_downloads" ("id" serial primary key, "user_groups" integer[], "path" character varying, "retrieval_path" character varying, "retrieved_items" character varying, "user_id" integer NOT NULL, "nfs_store_container_id" integer NOT NULL, "created_at" timestamp, "updated_at" timestamp) ;
ALTER TABLE "nfs_store_downloads" ADD CONSTRAINT "fk_rails_cd756b42dd"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_downloads" ADD CONSTRAINT "fk_rails_272f69e6af"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
CREATE TABLE "nfs_store_archived_files" ("id" serial primary key, "file_hash" character varying, "file_name" character varying NOT NULL, "content_type" character varying NOT NULL, "archive_file" character varying NOT NULL, "path" character varying NOT NULL, "file_size" bigint NOT NULL, "file_updated_at" timestamp, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL, "nfs_store_container_id" integer, "user_id" integer) ;
CREATE  INDEX  "index_nfs_store_archived_files_on_nfs_store_container_id" ON "nfs_store_archived_files"  ("nfs_store_container_id");
ALTER TABLE "nfs_store_archived_files" ADD CONSTRAINT "fk_rails_ecfa3cb151"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
ALTER TABLE "nfs_store_archived_files" ADD CONSTRAINT "fk_rails_2eab578259"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE UNIQUE INDEX  "nfs_store_uploads_unique_file" ON "nfs_store_uploads"  ("nfs_store_container_id", "file_hash", "file_name");
CREATE UNIQUE INDEX  "nfs_store_stored_files_unique_file" ON "nfs_store_stored_files"  ("nfs_store_container_id", "file_hash", "file_name");
ALTER TABLE "nfs_store_containers" ADD "master_id" integer;
CREATE  INDEX  "index_nfs_store_containers_on_master_id" ON "nfs_store_containers"  ("master_id");
ALTER TABLE "nfs_store_containers" ADD CONSTRAINT "fk_rails_2708bd6a94"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "nfs_store_containers" ADD "created_at" timestamp;
ALTER TABLE "nfs_store_containers" ADD "updated_at" timestamp;
ALTER TABLE "nfs_store_stored_files" ADD "title" character varying;
ALTER TABLE "nfs_store_stored_files" ADD "tags" character varying[];
ALTER TABLE "nfs_store_stored_files" ADD "description" character varying;
ALTER TABLE "nfs_store_archived_files" ADD "title" character varying;
ALTER TABLE "nfs_store_archived_files" ADD "tags" character varying[];
ALTER TABLE "nfs_store_archived_files" ADD "description" character varying;
DROP INDEX "nfs_store_uploads_unique_file";
ALTER TABLE "nfs_store_archived_files" ALTER COLUMN "file_hash" TYPE character varying;
ALTER TABLE "nfs_store_archived_files" ALTER "file_hash" DROP NOT NULL;
ALTER TABLE "nfs_store_uploads" ADD "path" character varying;
DROP INDEX "nfs_store_stored_files_unique_file";
CREATE UNIQUE INDEX  "nfs_store_stored_files_unique_file" ON "nfs_store_stored_files"  ("nfs_store_container_id", "file_hash", "file_name", "path");
ALTER TABLE "nfs_store_archived_files" DROP "tags";
ALTER TABLE "nfs_store_stored_files" DROP "tags";
ALTER TABLE "app_configurations" ADD "role_name" character varying;
ALTER TABLE "users" ADD "authentication_token" character varying(30);
CREATE UNIQUE INDEX  "index_users_on_authentication_token" ON "users"  ("authentication_token");
ALTER TABLE "external_identifiers" ADD "extra_fields" character varying;

  alter table external_identifier_history add column extra_fields varchar;
  
  CREATE or REPLACE FUNCTION ml_app.log_external_identifier_update() RETURNS trigger
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
                        extra_fields,
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
                        NEW.extra_fields,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;


;
ALTER TABLE "nfs_store_uploads" ADD "nfs_store_stored_file_id" integer;
CREATE  INDEX  "index_nfs_store_uploads_on_nfs_store_stored_file_id" ON "nfs_store_uploads"  ("nfs_store_stored_file_id");
ALTER TABLE "nfs_store_uploads" ADD CONSTRAINT "fk_rails_4ff6d28f98"
FOREIGN KEY ("nfs_store_stored_file_id")
  REFERENCES "nfs_store_stored_files" ("id")
;
ALTER TABLE "nfs_store_stored_files" ADD "last_process_name_run" character varying;
ALTER TABLE "nfs_store_archived_files" ADD "nfs_store_stored_file_id" integer;
CREATE  INDEX  "index_nfs_store_archived_files_on_nfs_store_stored_file_id" ON "nfs_store_archived_files"  ("nfs_store_stored_file_id");
ALTER TABLE "nfs_store_archived_files" ADD CONSTRAINT "fk_rails_2b59e23148"
FOREIGN KEY ("nfs_store_stored_file_id")
  REFERENCES "nfs_store_stored_files" ("id")
;
CREATE TABLE "nfs_store_filters" ("id" serial primary key, "app_type_id" integer, "role_name" character varying, "user_id" integer, "resource_name" character varying, "filter" character varying, "description" character varying, "disabled" boolean, "admin_id" integer) ;
CREATE  INDEX  "index_nfs_store_filters_on_app_type_id" ON "nfs_store_filters"  ("app_type_id");
CREATE  INDEX  "index_nfs_store_filters_on_user_id" ON "nfs_store_filters"  ("user_id");
CREATE  INDEX  "index_nfs_store_filters_on_admin_id" ON "nfs_store_filters"  ("admin_id");
ALTER TABLE "nfs_store_filters" ADD CONSTRAINT "fk_rails_f547361daa"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "nfs_store_filters" ADD CONSTRAINT "fk_rails_0208c3b54d"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_filters" ADD CONSTRAINT "fk_rails_776e17eafd"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "nfs_store_stored_files" ADD "file_metadata" jsonb;
ALTER TABLE "nfs_store_archived_files" ADD "file_metadata" jsonb;
ALTER TABLE "model_references" ADD "disabled" boolean;

ALTER TABLE activity_log_history
ADD COLUMN blank_log_name varchar,
ADD COLUMN extra_log_types varchar,
ADD COLUMN hide_item_list_panel boolean,
ADD COLUMN main_log_name varchar,
ADD COLUMN process_name varchar,
ADD COLUMN table_name varchar
;


CREATE or REPLACE FUNCTION log_activity_log_update() RETURNS trigger
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
                blank_log_field_list,

                blank_log_name,
                extra_log_types,
                hide_item_list_panel,
                main_log_name,
                process_name,
                table_name
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
                NEW.blank_log_field_list,

                NEW.blank_log_name,
                NEW.extra_log_types,
                NEW.hide_item_list_panel,
                NEW.main_log_name,
                NEW.process_name,
                NEW.table_name
            ;
            RETURN NEW;
        END;
    $$;

;
ALTER TABLE "app_configurations" ADD "created_at" timestamp;
ALTER TABLE "app_configurations" ADD "updated_at" timestamp;


      BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create app_configurations name value app_type_id user_id role_name

      CREATE or REPLACE FUNCTION log_app_configuration_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO app_configuration_history
                  (
                      name,
                      value,
                      app_type_id,
                      user_id,
                      role_name,
                      admin_id,
                      disabled,
                      created_at,
                      updated_at,
                      app_configuration_id
                      )
                  SELECT
                      NEW.name,
                      NEW.value,
                      NEW.app_type_id,
                      NEW.user_id,
                      NEW.role_name,
                      NEW.admin_id,
                      NEW.disabled,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE app_configuration_history (
          id integer NOT NULL,
          name varchar,
          value varchar,
          app_type_id bigint,
          user_id bigint,
          role_name varchar,
          admin_id integer,
          disabled boolean,
          created_at timestamp without time zone,
          updated_at timestamp without time zone,
          app_configuration_id integer
      );

      CREATE SEQUENCE app_configuration_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE app_configuration_history_id_seq OWNED BY app_configuration_history.id;


      ALTER TABLE ONLY app_configuration_history ALTER COLUMN id SET DEFAULT nextval('app_configuration_history_id_seq'::regclass);

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT app_configuration_history_pkey PRIMARY KEY (id);

      CREATE INDEX index_app_configuration_history_on_app_configuration_id ON app_configuration_history USING btree (app_configuration_id);
      CREATE INDEX index_app_configuration_history_on_admin_id ON app_configuration_history USING btree (admin_id);

      CREATE TRIGGER app_configuration_history_insert AFTER INSERT ON app_configurations FOR EACH ROW EXECUTE PROCEDURE log_app_configuration_update();
      CREATE TRIGGER app_configuration_history_update AFTER UPDATE ON app_configurations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_app_configuration_update();

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT fk_app_configuration_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT fk_app_configuration_history_app_configurations FOREIGN KEY (app_configuration_id) REFERENCES app_configurations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;


;
ALTER TABLE "app_types" ADD "created_at" timestamp;
ALTER TABLE "app_types" ADD "updated_at" timestamp;

 BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create app_types name label

     CREATE OR REPLACE FUNCTION log_app_type_update() RETURNS trigger
         LANGUAGE plpgsql
         AS $$
             BEGIN
                 INSERT INTO app_type_history
                 (
                     name,
                     label,
                     admin_id,
                     disabled,
                     created_at,
                     updated_at,
                     app_type_id
                     )
                 SELECT
                     NEW.name,
                     NEW.label,
                     NEW.admin_id,
                     NEW.disabled,
                     NEW.created_at,
                     NEW.updated_at,
                     NEW.id
                 ;
                 RETURN NEW;
             END;
         $$;

     CREATE TABLE app_type_history (
         id integer NOT NULL,
         name varchar,
         label varchar,
         admin_id integer,
         disabled boolean,
         created_at timestamp without time zone,
         updated_at timestamp without time zone,
         app_type_id integer
     );

     CREATE SEQUENCE app_type_history_id_seq
         START WITH 1
         INCREMENT BY 1
         NO MINVALUE
         NO MAXVALUE
         CACHE 1;

     ALTER SEQUENCE app_type_history_id_seq OWNED BY app_type_history.id;


     ALTER TABLE ONLY app_type_history ALTER COLUMN id SET DEFAULT nextval('app_type_history_id_seq'::regclass);

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT app_type_history_pkey PRIMARY KEY (id);

     CREATE INDEX index_app_type_history_on_app_type_id ON app_type_history USING btree (app_type_id);
     CREATE INDEX index_app_type_history_on_admin_id ON app_type_history USING btree (admin_id);

     CREATE TRIGGER app_type_history_insert AFTER INSERT ON app_types FOR EACH ROW EXECUTE PROCEDURE log_app_type_update();
     CREATE TRIGGER app_type_history_update AFTER UPDATE ON app_types FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_app_type_update();

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT fk_app_type_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT fk_app_type_history_app_types FOREIGN KEY (app_type_id) REFERENCES app_types(id);

     GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
     GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
     GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

     COMMIT;

;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create message_templates name template_type template

CREATE OR REPLACE FUNCTION log_message_template_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO message_template_history
            (
                name,
                template_type,
                template,
                admin_id,
                disabled,
                created_at,
                updated_at,
                message_template_id
                )
            SELECT
                NEW.name,
                NEW.template_type,
                NEW.template,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE message_template_history (
    id integer NOT NULL,
    name varchar,
    template_type varchar,
    template varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_template_id integer
);

CREATE SEQUENCE message_template_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE message_template_history_id_seq OWNED BY message_template_history.id;


ALTER TABLE ONLY message_template_history ALTER COLUMN id SET DEFAULT nextval('message_template_history_id_seq'::regclass);

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT message_template_history_pkey PRIMARY KEY (id);

CREATE INDEX index_message_template_history_on_message_template_id ON message_template_history USING btree (message_template_id);
CREATE INDEX index_message_template_history_on_admin_id ON message_template_history USING btree (admin_id);

CREATE TRIGGER message_template_history_insert AFTER INSERT ON message_templates FOR EACH ROW EXECUTE PROCEDURE log_message_template_update();
CREATE TRIGGER message_template_history_update AFTER UPDATE ON message_templates FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_message_template_update();

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT fk_message_template_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT fk_message_template_history_message_templates FOREIGN KEY (message_template_id) REFERENCES message_templates(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

CREATE OR REPLACE FUNCTION log_page_layout_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO page_layout_history
            (
                layout_name,
                panel_name,
                panel_label,
                panel_position,
                options,
                admin_id,
                disabled,
                created_at,
                updated_at,
                page_layout_id
                )
            SELECT
                NEW.layout_name,
                NEW.panel_name,
                NEW.panel_label,
                NEW.panel_position,
                NEW.options,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE page_layout_history (
    id integer NOT NULL,
    layout_name varchar,
    panel_name varchar,
    panel_label varchar,
    panel_position varchar,
    options varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    page_layout_id integer
);

CREATE SEQUENCE page_layout_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE page_layout_history_id_seq OWNED BY page_layout_history.id;


ALTER TABLE ONLY page_layout_history ALTER COLUMN id SET DEFAULT nextval('page_layout_history_id_seq'::regclass);

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT page_layout_history_pkey PRIMARY KEY (id);

CREATE INDEX index_page_layout_history_on_page_layout_id ON page_layout_history USING btree (page_layout_id);
CREATE INDEX index_page_layout_history_on_admin_id ON page_layout_history USING btree (admin_id);

CREATE TRIGGER page_layout_history_insert AFTER INSERT ON page_layouts FOR EACH ROW EXECUTE PROCEDURE log_page_layout_update();
CREATE TRIGGER page_layout_history_update AFTER UPDATE ON page_layouts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_page_layout_update();

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT fk_page_layout_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT fk_page_layout_history_page_layouts FOREIGN KEY (page_layout_id) REFERENCES page_layouts(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

;
ALTER TABLE "user_access_controls" ADD "created_at" timestamp;
ALTER TABLE "user_access_controls" ADD "updated_at" timestamp;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create user_access_controls user_id resource_type resource_name options access app_type_id role_name

CREATE OR REPLACE FUNCTION log_user_access_control_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_access_control_history
            (
                user_id,
                resource_type,
                resource_name,
                options,
                access,
                app_type_id,
                role_name,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_access_control_id
                )
            SELECT
                NEW.user_id,
                NEW.resource_type,
                NEW.resource_name,
                NEW.options,
                NEW.access,
                NEW.app_type_id,
                NEW.role_name,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE user_access_control_history (
    id integer NOT NULL,
    user_id bigint,
    resource_type varchar,
    resource_name varchar,
    options varchar,
    access varchar,
    app_type_id bigint,
    role_name varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_access_control_id integer
);

CREATE SEQUENCE user_access_control_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_access_control_history_id_seq OWNED BY user_access_control_history.id;


ALTER TABLE ONLY user_access_control_history ALTER COLUMN id SET DEFAULT nextval('user_access_control_history_id_seq'::regclass);

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT user_access_control_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_access_control_history_on_user_access_control_id ON user_access_control_history USING btree (user_access_control_id);
CREATE INDEX index_user_access_control_history_on_admin_id ON user_access_control_history USING btree (admin_id);

CREATE TRIGGER user_access_control_history_insert AFTER INSERT ON user_access_controls FOR EACH ROW EXECUTE PROCEDURE log_user_access_control_update();
CREATE TRIGGER user_access_control_history_update AFTER UPDATE ON user_access_controls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_access_control_update();

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_user_access_controls FOREIGN KEY (user_access_control_id) REFERENCES user_access_controls(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create user_roles app_type_id role_name user_id

CREATE OR REPLACE FUNCTION log_user_role_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_role_history
            (
                app_type_id,
                role_name,
                user_id,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_role_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE user_role_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name varchar,
    user_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_role_id integer
);

CREATE SEQUENCE user_role_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_role_history_id_seq OWNED BY user_role_history.id;


ALTER TABLE ONLY user_role_history ALTER COLUMN id SET DEFAULT nextval('user_role_history_id_seq'::regclass);

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT user_role_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_role_history_on_user_role_id ON user_role_history USING btree (user_role_id);
CREATE INDEX index_user_role_history_on_admin_id ON user_role_history USING btree (admin_id);

CREATE TRIGGER user_role_history_insert AFTER INSERT ON user_roles FOR EACH ROW EXECUTE PROCEDURE log_user_role_update();
CREATE TRIGGER user_role_history_update AFTER UPDATE ON user_roles FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_role_update();

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT fk_user_role_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT fk_user_role_history_user_roles FOREIGN KEY (user_role_id) REFERENCES user_roles(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

;
ALTER TABLE "nfs_store_filters" ADD "created_at" timestamp;
ALTER TABLE "nfs_store_filters" ADD "updated_at" timestamp;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create nfs_store_filters app_type_id role_name user_id resource_name filter description

CREATE OR REPLACE FUNCTION log_nfs_store_filter_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_filter_history
            (
                app_type_id,
                role_name,
                user_id,
                resource_name,
                filter,
                description,
                admin_id,
                disabled,
                created_at,
                updated_at,
                nfs_store_filter_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.resource_name,
                NEW.filter,
                NEW.description,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_filter_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name varchar,
    user_id bigint,
    resource_name varchar,
    filter varchar,
    description varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_filter_id integer
);

CREATE SEQUENCE nfs_store_filter_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_filter_history_id_seq OWNED BY nfs_store_filter_history.id;


ALTER TABLE ONLY nfs_store_filter_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_filter_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT nfs_store_filter_history_pkey PRIMARY KEY (id);

CREATE INDEX index_nfs_store_filter_history_on_nfs_store_filter_id ON nfs_store_filter_history USING btree (nfs_store_filter_id);
CREATE INDEX index_nfs_store_filter_history_on_admin_id ON nfs_store_filter_history USING btree (admin_id);

CREATE TRIGGER nfs_store_filter_history_insert AFTER INSERT ON nfs_store_filters FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_filter_update();
CREATE TRIGGER nfs_store_filter_history_update AFTER UPDATE ON nfs_store_filters FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_filter_update();

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY nfs_store_filter_history
    ADD CONSTRAINT fk_nfs_store_filter_history_nfs_store_filters FOREIGN KEY (nfs_store_filter_id) REFERENCES nfs_store_filters(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

;

-- Command line:
-- table_generators/generate.sh item_history_table create nfs_store_containers name app_type_id nfs_store_container_id

CREATE FUNCTION log_nfs_store_container_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_container_history
            (
                master_id,
                name,
                app_type_id,
                orig_nfs_store_container_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_container_id
                )
            SELECT
                NEW.master_id,
                NEW.name,
                NEW.app_type_id,
                NEW.nfs_store_container_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_container_history (
    id integer NOT NULL,
    master_id integer,
    name varchar,
    app_type_id bigint,
    orig_nfs_store_container_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_container_id integer
);

CREATE SEQUENCE nfs_store_container_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_container_history_id_seq OWNED BY nfs_store_container_history.id;

ALTER TABLE ONLY nfs_store_container_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_container_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT nfs_store_container_history_pkey PRIMARY KEY (id);

CREATE INDEX index_nfs_store_container_history_on_master_id ON nfs_store_container_history USING btree (master_id);

CREATE INDEX index_nfs_store_container_history_on_nfs_store_container_id ON nfs_store_container_history USING btree (nfs_store_container_id);
CREATE INDEX index_nfs_store_container_history_on_user_id ON nfs_store_container_history USING btree (user_id);

CREATE TRIGGER nfs_store_container_history_insert AFTER INSERT ON nfs_store_containers FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_container_update();
CREATE TRIGGER nfs_store_container_history_update AFTER UPDATE ON nfs_store_containers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_container_update();

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE ONLY nfs_store_container_history
    ADD CONSTRAINT fk_nfs_store_container_history_nfs_store_containers FOREIGN KEY (nfs_store_container_id) REFERENCES nfs_store_containers(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

;

-- Command line:
-- table_generators/generate.sh item_history_table create nfs_store_archived_files file_hash file_name content_type archive_file path file_size file_updated_at nfs_store_container_id title description file_metadata nfs_store_stored_file_id

CREATE FUNCTION log_nfs_store_archived_file_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_archived_file_history
            (
                file_hash,
                file_name,
                content_type,
                archive_file,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                nfs_store_stored_file_id,
                user_id,
                created_at,
                updated_at,
                nfs_store_archived_file_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.archive_file,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.nfs_store_stored_file_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_archived_file_history (
    id integer NOT NULL,
    file_hash varchar,
    file_name varchar,
    content_type varchar,
    archive_file varchar,
    path varchar,
    file_size varchar,
    file_updated_at varchar,
    nfs_store_container_id bigint,
    title varchar,
    description varchar,
    file_metadata varchar,
    nfs_store_stored_file_id bigint,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_archived_file_id integer
);

CREATE SEQUENCE nfs_store_archived_file_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_archived_file_history_id_seq OWNED BY nfs_store_archived_file_history.id;

ALTER TABLE ONLY nfs_store_archived_file_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_archived_file_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT nfs_store_archived_file_history_pkey PRIMARY KEY (id);


CREATE INDEX index_nfs_store_archived_file_history_on_nfs_store_archived_file_id ON nfs_store_archived_file_history USING btree (nfs_store_archived_file_id);
CREATE INDEX index_nfs_store_archived_file_history_on_user_id ON nfs_store_archived_file_history USING btree (user_id);

CREATE TRIGGER nfs_store_archived_file_history_insert AFTER INSERT ON nfs_store_archived_files FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_archived_file_update();
CREATE TRIGGER nfs_store_archived_file_history_update AFTER UPDATE ON nfs_store_archived_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_archived_file_update();

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY nfs_store_archived_file_history
    ADD CONSTRAINT fk_nfs_store_archived_file_history_nfs_store_archived_files FOREIGN KEY (nfs_store_archived_file_id) REFERENCES nfs_store_archived_files(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

;

-- Command line:
-- table_generators/generate.sh item_history_table create nfs_store_stored_files file_hash file_name content_type path file_size file_updated_at nfs_store_container_id title description file_metadata last_process_name_run

CREATE FUNCTION log_nfs_store_stored_file_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO nfs_store_stored_file_history
            (
                file_hash,
                file_name,
                content_type,
                path,
                file_size,
                file_updated_at,
                nfs_store_container_id,
                title,
                description,
                file_metadata,
                last_process_name_run,
                user_id,
                created_at,
                updated_at,
                nfs_store_stored_file_id
                )
            SELECT
                NEW.file_hash,
                NEW.file_name,
                NEW.content_type,
                NEW.path,
                NEW.file_size,
                NEW.file_updated_at,
                NEW.nfs_store_container_id,
                NEW.title,
                NEW.description,
                NEW.file_metadata,
                NEW.last_process_name_run,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE nfs_store_stored_file_history (
    id integer NOT NULL,
    file_hash varchar,
    file_name varchar,
    content_type varchar,
    path varchar,
    file_size varchar,
    file_updated_at varchar,
    nfs_store_container_id bigint,
    title varchar,
    description varchar,
    file_metadata varchar,
    last_process_name_run varchar,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nfs_store_stored_file_id integer
);

CREATE SEQUENCE nfs_store_stored_file_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE nfs_store_stored_file_history_id_seq OWNED BY nfs_store_stored_file_history.id;

ALTER TABLE ONLY nfs_store_stored_file_history ALTER COLUMN id SET DEFAULT nextval('nfs_store_stored_file_history_id_seq'::regclass);

ALTER TABLE ONLY nfs_store_stored_file_history
    ADD CONSTRAINT nfs_store_stored_file_history_pkey PRIMARY KEY (id);


CREATE INDEX index_nfs_store_stored_file_history_on_nfs_store_stored_file_id ON nfs_store_stored_file_history USING btree (nfs_store_stored_file_id);
CREATE INDEX index_nfs_store_stored_file_history_on_user_id ON nfs_store_stored_file_history USING btree (user_id);

CREATE TRIGGER nfs_store_stored_file_history_insert AFTER INSERT ON nfs_store_stored_files FOR EACH ROW EXECUTE PROCEDURE log_nfs_store_stored_file_update();
CREATE TRIGGER nfs_store_stored_file_history_update AFTER UPDATE ON nfs_store_stored_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_nfs_store_stored_file_update();

ALTER TABLE ONLY nfs_store_stored_file_history
    ADD CONSTRAINT fk_nfs_store_stored_file_history_users FOREIGN KEY (user_id) REFERENCES users(id);


ALTER TABLE ONLY nfs_store_stored_file_history
    ADD CONSTRAINT fk_nfs_store_stored_file_history_nfs_store_stored_files FOREIGN KEY (nfs_store_stored_file_id) REFERENCES nfs_store_stored_files(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create dynamic_models name table_name schema_name primary_key_name foreign_key_name description position category table_key_name field_list result_order options

    CREATE OR REPLACE FUNCTION log_dynamic_model_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO dynamic_model_history
                (
                    name,
                    table_name,
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order,
                    options,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    dynamic_model_id
                    )
                SELECT
                    NEW.name,
                    NEW.table_name,
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order,
                    NEW.options,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

    ALTER TABLE dynamic_model_history
        ADD COLUMN options varchar;


    COMMIT;

;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create external_identifiers name label external_id_attribute external_id_view_formatter external_id_edit_pattern prevent_edit pregenerate_ids min_id max_id alphanumeric extra_fields

CREATE OR REPLACE FUNCTION log_external_identifier_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO external_identifier_history
            (
                name,
                label,
                external_id_attribute,
                external_id_view_formatter,
                external_id_edit_pattern,
                prevent_edit,
                pregenerate_ids,
                min_id,
                max_id,
                alphanumeric,
                extra_fields,
                admin_id,
                disabled,
                created_at,
                updated_at,
                external_identifier_id
                )
            SELECT
                NEW.name,
                NEW.label,
                NEW.external_id_attribute,
                NEW.external_id_view_formatter,
                NEW.external_id_edit_pattern,
                NEW.prevent_edit,
                NEW.pregenerate_ids,
                NEW.min_id,
                NEW.max_id,
                NEW.alphanumeric,
                NEW.extra_fields,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

ALTER TABLE external_identifier_history
    ADD COLUMN alphanumeric BOOLEAN;


;

    CREATE OR REPLACE FUNCTION log_message_template_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO message_template_history
                (
                    name,
                    template_type,
                    message_type,
                    template,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    message_template_id
                    )
                SELECT
                    NEW.name,
                    NEW.template_type,
                    NEW.message_type,
                    NEW.template,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


    ALTER TABLE message_template_history
        ADD COLUMN message_type VARCHAR;


;

    BEGIN;

    -- Command line:
    -- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

    CREATE OR REPLACE FUNCTION log_page_layout_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO page_layout_history
                (
                    app_type_id,
                    layout_name,
                    panel_name,
                    panel_label,
                    panel_position,
                    options,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    page_layout_id
                    )
                SELECT
                    NEW.app_type_id,
                    NEW.layout_name,
                    NEW.panel_name,
                    NEW.panel_label,
                    NEW.panel_position,
                    NEW.options,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


    ALTER TABLE page_layout_history
        ADD COLUMN app_type_id VARCHAR;


;

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

CREATE OR REPLACE FUNCTION log_user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_history
            (
                email,
                encrypted_password,
                reset_password_token,
                reset_password_sent_at,
                remember_created_at,
                sign_in_count,
                current_sign_in_at,
                last_sign_in_at,
                current_sign_in_ip,
                last_sign_in_ip,
                failed_attempts,
                unlock_token,
                locked_at,
                app_type_id,
                authentication_token,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_id
                )
            SELECT
                NEW.email,
                NEW.encrypted_password,
                NEW.reset_password_token,
                NEW.reset_password_sent_at,
                NEW.remember_created_at,
                NEW.sign_in_count,
                NEW.current_sign_in_at,
                NEW.last_sign_in_at,
                NEW.current_sign_in_ip,
                NEW.last_sign_in_ip,
                NEW.failed_attempts,
                NEW.unlock_token,
                NEW.locked_at,
                NEW.app_type_id,
                NEW.authentication_token,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;



ALTER TABLE user_history
    ADD COLUMN authentication_token VARCHAR;


;
ALTER TABLE "nfs_store_downloads" ALTER "nfs_store_container_id" DROP NOT NULL;
ALTER TABLE "nfs_store_downloads" ADD "nfs_store_container_ids" integer[];

CREATE OR REPLACE FUNCTION filestore_report_perform_action(cid integer, altype varchar, alid integer, sf nfs_store_stored_files, af nfs_store_archived_files) RETURNS jsonb AS $$
	DECLARE
        jo jsonb;
        rt varchar;
        fn varchar;
        alt varchar;
    BEGIN

        rt := '"' || (CASE WHEN af.id IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END) || '"';
        fn := '"' || (CASE WHEN af.id IS NOT NULL THEN af.file_name ELSE sf.file_name END) || '"';
		alt := '"' || altype || '"';
        jo := '{}';

        jo := jsonb_set(jo, '{perform_action}', '"/nfs_store/downloads/!container_id"');
        jo := jsonb_set(jo, '{container_id}', cid::varchar::jsonb);
        jo := jsonb_set(jo, '{download_id}', coalesce(af.id, sf.id)::varchar::jsonb);
        jo := jsonb_set(jo, '{activity_log_type}', alt::jsonb);
        jo := jsonb_set(jo, '{activity_log_id}', alid::varchar::jsonb);
        jo := jsonb_set(jo, '{retrieval_type}', rt::jsonb );
        jo := jsonb_set(jo, '{label}', fn::jsonb);

        return jo;

	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION filestore_report_select_fields(cid integer, altype varchar, alid integer, sfid integer, afid integer) RETURNS jsonb AS $$
	DECLARE
        jo jsonb;
        joid jsonb;
        rt varchar;
        alt varchar;
    BEGIN

    	rt := '"' || CASE WHEN afid IS NOT NULL THEN 'archived_file' ELSE 'stored_file' END || '"';
    	alt := '"' || altype || '"';

        joid := '{}'::jsonb;
        joid := jsonb_set(joid, '{id}', coalesce(afid, sfid)::varchar::jsonb);
        joid := jsonb_set(joid, '{retrieval_type}', rt::jsonb );
        joid := jsonb_set(joid, '{container_id}', cid::varchar::jsonb);
        joid := jsonb_set(joid, '{activity_log_type}', alt::jsonb);
        joid := jsonb_set(joid, '{activity_log_id}', alid::varchar::jsonb);


    	jo := '{}'::jsonb;
  		jo := jsonb_set(jo, '{field_name}', '"nfs_store_download[selected_items][]"');
    	jo := jsonb_set(jo, '{value}', joid);
    	return jo;

	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION filestore_report_file_path(sf nfs_store_stored_files, af nfs_store_archived_files) RETURNS VARCHAR AS $$
    BEGIN

      return CASE WHEN af.id IS NOT NULL THEN
        coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path
        ELSE sf.path
      END;

	END;
$$ LANGUAGE plpgsql;


;
CREATE TABLE "users_contact_infos" ("id" serial primary key, "user_id" integer, "sms_number" character varying, "phone_number" character varying, "alt_email" character varying, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_users_contact_infos_on_user_id" ON "users_contact_infos"  ("user_id");
ALTER TABLE "users_contact_infos" ADD CONSTRAINT "fk_rails_4decdf690b"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "users_contact_infos" ADD "admin_id" integer;
CREATE  INDEX  "index_users_contact_infos_on_admin_id" ON "users_contact_infos"  ("admin_id");
ALTER TABLE "users_contact_infos" ADD CONSTRAINT "fk_rails_7808f5fdb3"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "users_contact_infos" ADD "disabled" boolean;
ALTER TABLE "users" ADD "encrypted_otp_secret" character varying;
ALTER TABLE "users" ADD "encrypted_otp_secret_iv" character varying;
ALTER TABLE "users" ADD "encrypted_otp_secret_salt" character varying;
ALTER TABLE "users" ADD "consumed_timestep" integer;
ALTER TABLE "users" ADD "otp_required_for_login" boolean;
ALTER TABLE "admins" ADD "encrypted_otp_secret" character varying;
ALTER TABLE "admins" ADD "encrypted_otp_secret_iv" character varying;
ALTER TABLE "admins" ADD "encrypted_otp_secret_salt" character varying;
ALTER TABLE "admins" ADD "consumed_timestep" integer;
ALTER TABLE "admins" ADD "otp_required_for_login" boolean;
ALTER TABLE "admins" ADD "reset_password_sent_at" timestamp;
ALTER TABLE "users" ADD "password_updated_at" timestamp;
ALTER TABLE "admins" ADD "password_updated_at" timestamp;
CREATE TABLE "nfs_store_imports" ("id" serial primary key, "file_hash" character varying, "file_name" character varying, "user_id" integer, "nfs_store_container_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
ALTER TABLE "nfs_store_imports" ADD CONSTRAINT "fk_rails_0ad81c489c"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_imports" ADD CONSTRAINT "fk_rails_0d30944d1b"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
ALTER TABLE "users" ADD "first_name" character varying;
ALTER TABLE "users" ADD "last_name" character varying;
ALTER TABLE "admins" ADD "first_name" character varying;
ALTER TABLE "admins" ADD "last_name" character varying;

    alter table ml_app.user_history
    add column encrypted_otp_secret character varying,
    add column encrypted_otp_secret_iv character varying,
    add column encrypted_otp_secret_salt character varying,
    add column consumed_timestep integer,
    add column otp_required_for_login boolean,
    add column password_updated_at timestamp without time zone,
    add column first_name varchar,
    add column last_name varchar
    ;

    CREATE OR REPLACE FUNCTION ml_app.log_user_update()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
    BEGIN
      INSERT INTO user_history
      (
            user_id,
            email,
            encrypted_password,
            reset_password_token,
            reset_password_sent_at,
            remember_created_at,
            sign_in_count,
            current_sign_in_at,
            last_sign_in_at,
            current_sign_in_ip ,
            last_sign_in_ip ,
            created_at ,
            updated_at,
            failed_attempts,
            unlock_token,
            locked_at,
            disabled ,
            admin_id,
            app_type_id,
            authentication_token,
            encrypted_otp_secret,
            encrypted_otp_secret_iv,
            encrypted_otp_secret_salt,
            consumed_timestep,
            otp_required_for_login,
            password_updated_at,
            first_name,
            last_name
      )
      SELECT
            NEW.id,
            NEW.email,
            NEW.encrypted_password,
            NEW.reset_password_token,
            NEW.reset_password_sent_at,
            NEW.remember_created_at,
            NEW.sign_in_count,
            NEW.current_sign_in_at,
            NEW.last_sign_in_at,
            NEW.current_sign_in_ip ,
            NEW.last_sign_in_ip ,
            NEW.created_at ,
            NEW.updated_at,
            NEW.failed_attempts,
            NEW.unlock_token,
            NEW.locked_at,
            NEW.disabled ,
            NEW.admin_id,
            NEW.app_type_id,
            NEW.authentication_token,
            NEW.encrypted_otp_secret,
            NEW.encrypted_otp_secret_iv,
            NEW.encrypted_otp_secret_salt,
            NEW.consumed_timestep,
            NEW.otp_required_for_login,
            NEW.password_updated_at,
            NEW.first_name,
            NEW.last_name
            ;
            RETURN NEW;
        END;
    $function$;


    alter table ml_app.admin_history
    add column encrypted_otp_secret character varying,
    add column encrypted_otp_secret_iv character varying,
    add column encrypted_otp_secret_salt character varying,
    add column consumed_timestep integer,
    add column otp_required_for_login boolean,
    add column reset_password_sent_at timestamp without time zone,
    add column password_updated_at timestamp without time zone
    ;


    CREATE OR REPLACE FUNCTION ml_app.log_admin_update()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
    BEGIN
      INSERT INTO admin_history
      (
        admin_id,
        email,
        encrypted_password,
        sign_in_count,
        current_sign_in_at,
        last_sign_in_at,
        current_sign_in_ip ,
        last_sign_in_ip ,
        created_at ,
        updated_at,
        failed_attempts,
        unlock_token,
        locked_at,
        disabled,
        encrypted_otp_secret,
        encrypted_otp_secret_iv,
        encrypted_otp_secret_salt,
        consumed_timestep,
        otp_required_for_login,
        reset_password_sent_at,
        password_updated_at

      )
      SELECT
        NEW.id,
        NEW.email,
        NEW.encrypted_password,
        NEW.sign_in_count,
        NEW.current_sign_in_at,
        NEW.last_sign_in_at,
        NEW.current_sign_in_ip ,
        NEW.last_sign_in_ip ,
        NEW.created_at ,
        NEW.updated_at,
        NEW.failed_attempts,
        NEW.unlock_token,
        NEW.locked_at,
        NEW.disabled,
        NEW.encrypted_otp_secret,
        NEW.encrypted_otp_secret_iv,
        NEW.encrypted_otp_secret_salt,
        NEW.consumed_timestep,
        NEW.otp_required_for_login,
        NEW.reset_password_sent_at,
        NEW.password_updated_at
        ;
        RETURN NEW;
    END;
    $function$;


;
ALTER TABLE "message_notifications" ADD "role_name" character varying;
CREATE TABLE "nfs_store_trash_actions" ("id" serial primary key, "user_groups" integer[], "path" character varying, "retrieval_path" character varying, "trashed_items" character varying, "nfs_store_container_ids" integer[], "user_id" integer NOT NULL, "nfs_store_container_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
ALTER TABLE "nfs_store_trash_actions" ADD CONSTRAINT "fk_rails_de41d50f67"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_trash_actions" ADD CONSTRAINT "fk_rails_0e2ecd8d43"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;
ALTER TABLE "nfs_store_uploads" ADD "upload_set" character varying;
CREATE  INDEX  "index_nfs_store_uploads_on_upload_set" ON "nfs_store_uploads"  ("upload_set");
ALTER TABLE "message_notifications" ADD "content_template_text" character varying;
ALTER TABLE "message_notifications" RENAME COLUMN "recipient_emails" TO "recipient_data";
ALTER TABLE "message_notifications" ADD "importance" character varying;
ALTER TABLE "reports" ADD "short_name" character varying;
ALTER TABLE "reports" ADD "options" character varying;
ALTER TABLE "page_layouts" ADD "description" character varying;
ALTER TABLE "activity_logs" ADD "category" character varying;
ALTER TABLE "message_templates" ADD "category" character varying;



  ALTER TABLE report_history
    add column short_name character varying,
    add column options character varying
  ;


  CREATE or REPLACE FUNCTION log_report_update() RETURNS trigger
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
                    item_type,
                    short_name,
                    options
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
                NEW.item_type,
                NEW.short_name,
                NEW.options
            ;
            RETURN NEW;
        END;
    $$;


    ALTER table page_layout_history
    add column description varchar;

    CREATE or REPLACE FUNCTION log_page_layout_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
          BEGIN
              INSERT INTO page_layout_history
              (
                      page_layout_id,
                      app_type_id,
                      layout_name,
                      panel_name,
                      panel_label,
                      panel_position,
                      options,
                      disabled,
                      admin_id,
                      created_at,
                      updated_at,
                      description
                  )
              SELECT
                  NEW.id,
                  NEW.app_type_id,
                  NEW.layout_name,
                  NEW.panel_name,
                  NEW.panel_label,
                  NEW.panel_position,
                  NEW.options,
                  NEW.disabled,
                  NEW.admin_id,
                  NEW.created_at,
                  NEW.updated_at,
                  NEW.description
              ;
              RETURN NEW;
          END;
      $$;


      ALTER TABLE activity_log_history
        add column category character varying
      ;

      CREATE or REPLACE FUNCTION log_activity_log_update() RETURNS trigger
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
                      blank_log_field_list,
                      blank_log_name,
                      extra_log_types,
                      hide_item_list_panel,
                      main_log_name,
                      process_name,
                      table_name,
                      category
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
                      NEW.blank_log_field_list,
                      NEW.blank_log_name,
                      NEW.extra_log_types,
                      NEW.hide_item_list_panel,
                      NEW.main_log_name,
                      NEW.process_name,
                      NEW.table_name,
                      NEW.category
                  ;
                  RETURN NEW;
              END;
          $$;



      ALTER TABLE message_template_history
        add column category character varying
      ;

      CREATE or REPLACE FUNCTION log_message_template_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
                  BEGIN
                      INSERT INTO message_template_history
                      (
                          name,
                          template_type,
                          message_type,
                          template,
                          category,
                          admin_id,
                          disabled,
                          created_at,
                          updated_at,
                          message_template_id
                          )
                      SELECT
                          NEW.name,
                          NEW.template_type,
                          NEW.message_type,
                          NEW.template,
                          NEW.category,
                          NEW.admin_id,
                          NEW.disabled,
                          NEW.created_at,
                          NEW.updated_at,
                          NEW.id
                      ;
                      RETURN NEW;
                  END;
              $$;


;
CREATE TABLE "config_libraries" ("id" serial primary key, "category" character varying, "name" character varying, "options" character varying, "format" character varying, "disabled" boolean DEFAULT 'f', "admin_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
CREATE  INDEX  "index_config_libraries_on_admin_id" ON "config_libraries"  ("admin_id");
ALTER TABLE "config_libraries" ADD CONSTRAINT "fk_rails_da3ba4f850"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
CREATE TABLE "config_library_history" ("id" serial primary key, "category" character varying, "name" character varying, "options" character varying, "format" character varying, "disabled" boolean DEFAULT 'f', "admin_id" integer, "config_library_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
CREATE  INDEX  "index_config_library_history_on_admin_id" ON "config_library_history"  ("admin_id");
CREATE  INDEX  "index_config_library_history_on_config_library_id" ON "config_library_history"  ("config_library_id");
ALTER TABLE "config_library_history" ADD CONSTRAINT "fk_rails_1ec40f248c"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "config_library_history" ADD CONSTRAINT "fk_rails_88664b466b"
FOREIGN KEY ("config_library_id")
  REFERENCES "config_libraries" ("id")
;

CREATE OR REPLACE FUNCTION ml_app.log_config_library_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO config_library_history
            (
                    config_library_id,
                    category,
                    name,
                    options,
                    format,
                    disabled,
                    admin_id,
                    updated_at,
                    created_at
                )
            SELECT
                NEW.id,
                NEW.category,
                NEW.name,
                NEW.options,
                NEW.format,
                NEW.disabled,
                NEW.admin_id,
                NEW.updated_at,
                NEW.created_at
            ;
            RETURN NEW;
        END;
    $$;


  CREATE TRIGGER config_library_history_insert AFTER INSERT ON ml_app.config_libraries FOR EACH ROW EXECUTE PROCEDURE ml_app.log_config_library_update();
  CREATE TRIGGER config_library_history_update AFTER UPDATE ON ml_app.config_libraries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_config_library_update();

;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20180723165621
20180725140502
20180814142112
20180814142559
20180814142560
20180814142561
20180814142562
20180814142924
20180814180843
20180815104221
20180817114138
20180817114157
20180818133205
20180821123717
20180822085118
20180822093147
20180830144523
20180831132605
20180911153518
20180913142103
20180924153547
20181002142656
20181002165822
20181003182428
20181004113953
20181008104204
20181030185123
20181108115216
20181113143210
20181113143327
20181113150331
20181113150713
20181113152652
20181113154525
20181113154855
20181113154920
20181113154942
20181113165948
20181113170144
20181113172429
20181113175031
20181113180608
20181113183446
20181113184022
20181113184516
20181113184920
20181113185315
20181205103333
20181206123849
20181220131156
20181220160047
20190130152053
20190130152208
20190131130024
20190201160559
20190201160606
20190225094021
20190226165932
20190226165938
20190226173917
20190312160404
20190312163119
20190416181222
20190502142561
20190517135351
20190523115611
20190528152006
20190612140618
20190614162317
20190624082535
20190628131713
20190709174613
20190709174638
20190711074003
20190711084434
\.

 commit; ;
