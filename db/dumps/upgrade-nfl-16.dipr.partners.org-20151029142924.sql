-- Script created @ 2015-10-29 14:29:24 -0400
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
