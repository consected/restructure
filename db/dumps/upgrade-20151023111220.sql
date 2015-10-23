-- Script created @ 2015-10-23 11:12:20 -0400
begin;
set search_path = ml_app;

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


insert into reports (name, sql, report_type, created_at, updated_at, description, disabled)
values ('Sage Assigned','select id, sage_id from sage_assignments where master_id is not null', 'regular_report', now(),now(), '', false),
('Sage Unassigned', 'select id, sage_id from sage_assignments where master_id is null', 'regular_report', now(),now(), '', false);

commit;
