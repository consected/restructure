-- Script created @ 2015-10-16 15:04:11 -0400
begin;
set search_path = ml_app;

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

commit;
