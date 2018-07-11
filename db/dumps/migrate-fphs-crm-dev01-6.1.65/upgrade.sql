-- Script created @ 2018-07-11 13:16:41 +0100
set search_path=ml_app;
 begin;  ;

CREATE TABLE "user_roles" ("id" serial primary key, "app_type_id" integer, "role_name" character varying, "user_id" integer, "admin_id" integer, "disabled" boolean DEFAULT 0 NOT NULL, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_user_roles_on_app_type_id" ON "user_roles"  ("app_type_id");
CREATE  INDEX  "index_user_roles_on_user_id" ON "user_roles"  ("user_id");
CREATE  INDEX  "index_user_roles_on_admin_id" ON "user_roles"  ("admin_id");
ALTER TABLE "user_roles" ADD CONSTRAINT "fk_rails_b345649dfe"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "user_roles" ADD CONSTRAINT "fk_rails_318345354e"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "user_roles" ADD CONSTRAINT "fk_rails_174e058eb3"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;
CREATE TABLE "page_layouts" ("id" serial primary key, "app_type_id" integer, "layout_name" character varying, "panel_name" character varying, "panel_label" character varying, "panel_position" integer, "options" character varying, "disabled" boolean, "admin_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_page_layouts_on_app_type_id" ON "page_layouts"  ("app_type_id");
CREATE  INDEX  "index_page_layouts_on_admin_id" ON "page_layouts"  ("admin_id");
ALTER TABLE "page_layouts" ADD CONSTRAINT "fk_rails_37a2f11066"
FOREIGN KEY ("app_type_id")
  REFERENCES "app_types" ("id")
;
ALTER TABLE "page_layouts" ADD CONSTRAINT "fk_rails_e410af4010"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;

CREATE TABLE "admin_action_logs" ("id" serial primary key, "admin_id" integer, "item_type" character varying, "item_id" integer, "action" character varying, "url" character varying, "prev_value" json, "new_value" json, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_admin_action_logs_on_admin_id" ON "admin_action_logs"  ("admin_id");
ALTER TABLE "admin_action_logs" ADD CONSTRAINT "fk_rails_3389f178f6"
FOREIGN KEY ("admin_id")
  REFERENCES "admins" ("id")
;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20180426091838
20180502082334
20180504080300
20180531091440
\.

 commit; ;
