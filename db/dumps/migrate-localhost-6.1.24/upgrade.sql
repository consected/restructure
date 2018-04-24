-- Script created @ 2018-04-24 18:03:21 +0100
set search_path=ml_app; 
 begin;  ;
CREATE TABLE "app_configurations" ("id" serial primary key, "name" character varying, "value" character varying, "disabled" boolean, "admin_id" integer) ;
CREATE  INDEX  "index_app_configurations_on_admin_id" ON "app_configurations"  ("admin_id");
ALTER TABLE "app_configurations" ADD CONSTRAINT "fk_rails_f0ac516fff"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "activity_logs" ADD "blank_log_name" character varying;
ALTER TABLE "activity_logs" ADD "extra_log_types" character varying;
ALTER TABLE "activity_logs" ADD "hide_item_list_panel" boolean;
ALTER TABLE "activity_logs" ADD "main_log_name" character varying;
ALTER TABLE "app_configurations" ADD "user_id" integer;
CREATE  INDEX  "index_app_configurations_on_user_id" ON "app_configurations"  ("user_id");
ALTER TABLE "app_configurations" ADD CONSTRAINT "fk_rails_00f31a00c4"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE TABLE "user_access_controls" ("id" serial primary key, "user_id" integer, "resource_type" character varying, "resource_name" character varying, "options" character varying, "access" character varying, "disabled" boolean, "admin_id" integer) ;
CREATE TABLE "app_types" ("id" serial primary key, "name" character varying, "label" character varying, "disabled" boolean, "admin_id" integer) ;
CREATE  INDEX  "index_app_types_on_admin_id" ON "app_types"  ("admin_id");
ALTER TABLE "app_types" ADD CONSTRAINT "fk_rails_8be93bcf4b"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
ALTER TABLE "app_configurations" ADD "app_type_id" integer;
CREATE  INDEX  "index_app_configurations_on_app_type_id" ON "app_configurations"  ("app_type_id");
ALTER TABLE "app_configurations" ADD CONSTRAINT "fk_rails_647c63b069"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "user_access_controls" ADD "app_type_id" integer;
CREATE  INDEX  "index_user_access_controls_on_app_type_id" ON "user_access_controls"  ("app_type_id");
ALTER TABLE "user_access_controls" ADD CONSTRAINT "fk_rails_8108e25f83"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "users" ADD "app_type_id" integer;
CREATE  INDEX  "index_users_on_app_type_id" ON "users"  ("app_type_id");
ALTER TABLE "users" ADD CONSTRAINT "fk_rails_6a971dc818"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "external_identifiers" ADD "alphanumeric" boolean;
CREATE TABLE "model_references" ("id" serial primary key, "from_record_type" character varying, "from_record_id" integer, "from_record_master_id" integer, "to_record_type" character varying, "to_record_id" integer, "to_record_master_id" integer, "user_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_model_references_on_from_record_master_id" ON "model_references"  ("from_record_master_id");
CREATE  INDEX  "index_model_references_on_to_record_master_id" ON "model_references"  ("to_record_master_id");
CREATE  INDEX  "index_model_references_on_user_id" ON "model_references"  ("user_id");
ALTER TABLE "model_references" ADD CONSTRAINT "fk_rails_4bbf83b940"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE  INDEX  "index_model_references_on_from_record_type_and_from_record_id" ON "model_references"  ("from_record_type", "from_record_id");
CREATE  INDEX  "index_model_references_on_to_record_type_and_to_record_id" ON "model_references"  ("to_record_type", "to_record_id");
ALTER TABLE "model_references" ADD CONSTRAINT "fk_rails_2d8072edea"
FOREIGN KEY ("to_record_master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "model_references" ADD CONSTRAINT "fk_rails_a4eb981c4a"
FOREIGN KEY ("from_record_master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "activity_log_player_contact_phones" ADD "extra_log_type" character varying;
CREATE TABLE "user_action_logs" ("id" serial primary key, "user_id" integer, "app_type_id" integer, "master_id" integer, "item_type" character varying, "item_id" integer, "index_action_ids" integer[], "action" character varying, "url" character varying, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_user_action_logs_on_user_id" ON "user_action_logs"  ("user_id");
CREATE  INDEX  "index_user_action_logs_on_app_type_id" ON "user_action_logs"  ("app_type_id");
CREATE  INDEX  "index_user_action_logs_on_master_id" ON "user_action_logs"  ("master_id");
ALTER TABLE "user_action_logs" ADD CONSTRAINT "fk_rails_cfc9dc539f"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "user_action_logs" ADD CONSTRAINT "fk_rails_c94bae872a"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "user_action_logs" ADD CONSTRAINT "fk_rails_08eec3f089"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "user_history" ADD "app_type_id" integer;
CREATE  INDEX  "index_user_history_on_app_type_id" ON "user_history"  ("app_type_id");
ALTER TABLE "user_history" ADD CONSTRAINT "fk_rails_af2f6ffc55"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;

    DROP FUNCTION if exists ml_app.log_user_update() cascade;

    CREATE FUNCTION ml_app.log_user_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
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
        app_type_id

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
        NEW.app_type_id
                ;
                RETURN NEW;
            END;
        $$;


        CREATE TRIGGER user_history_insert AFTER INSERT ON ml_app.users FOR EACH ROW EXECUTE PROCEDURE ml_app.log_user_update();
        CREATE TRIGGER user_history_update AFTER UPDATE ON ml_app.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_user_update();

;
ALTER TABLE "activity_logs" ADD "process_name" character varying;
ALTER TABLE "activity_logs" ADD "table_name" character varying;
CREATE TABLE "message_notifications" ("id" serial primary key, "app_type_id" integer, "master_id" integer, "user_id" integer, "item_id" integer, "item_type" character varying, "message_type" character varying, "recipient_user_ids" integer[], "layout_template_name" character varying, "content_template_name" character varying, "generated_content" character varying, "status" character varying, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_message_notifications_on_app_type_id" ON "message_notifications"  ("app_type_id");
CREATE  INDEX  "index_message_notifications_on_master_id" ON "message_notifications"  ("master_id");
CREATE  INDEX  "index_message_notifications_on_user_id" ON "message_notifications"  ("user_id");
ALTER TABLE "message_notifications" ADD CONSTRAINT "fk_rails_d3566ee56d"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "message_notifications" ADD CONSTRAINT "fk_rails_3a3553e146"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;
ALTER TABLE "message_notifications" ADD CONSTRAINT "fk_rails_fa6dbd15de"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
CREATE TABLE "message_templates" ("id" serial primary key, "name" character varying, "message_type" character varying, "template_type" character varying, "template" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_message_templates_on_admin_id" ON "message_templates"  ("admin_id");
ALTER TABLE "message_templates" ADD CONSTRAINT "fk_rails_4fe5122ed4"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
CREATE  INDEX  "index_message_notifications_status" ON "message_notifications" USING btree ("status");
ALTER TABLE "message_notifications" ADD "status_changed" character varying;
CREATE TABLE "delayed_jobs" ("id" serial primary key, "priority" integer DEFAULT 0 NOT NULL, "attempts" integer DEFAULT 0 NOT NULL, "handler" text NOT NULL, "last_error" text, "run_at" timestamp, "locked_at" timestamp, "failed_at" timestamp, "locked_by" character varying, "queue" character varying, "created_at" timestamp, "updated_at" timestamp) ;
CREATE  INDEX  "delayed_jobs_priority" ON "delayed_jobs"  ("priority", "run_at");
ALTER TABLE "message_notifications" ADD "subject" character varying;
ALTER TABLE "message_notifications" ADD "data" json;
ALTER TABLE "message_notifications" ADD "recipient_emails" character varying[];
ALTER TABLE "message_notifications" ADD "from_user_email" character varying;
ALTER TABLE "dynamic_models" ADD "options" character varying;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20180119173411
20180123111956
20180123154108
20180126120818
20180206173516
20180209145336
20180209152723
20180209152747
20180209171641
20180228145731
20180301114206
20180302144109
20180313091440
20180319133539
20180319133540
20180319175721
20180320105954
20180320113757
20180320154951
20180320183512
20180321082612
20180321095805
20180404150536
20180405141059
20180416145033
\.

 commit; ;
