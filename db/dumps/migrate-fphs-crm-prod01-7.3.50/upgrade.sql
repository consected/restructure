-- Script created @ 2019-10-01 10:01:25 +0100
set search_path=ml_app; 
 begin;  ;
ALTER TABLE "message_notifications" ADD "extra_substitutions" character varying;
CREATE TABLE "nfs_store_move_actions" ("id" serial primary key, "user_groups" integer[], "path" character varying, "new_path" character varying, "retrieval_path" character varying, "moved_items" character varying, "nfs_store_container_ids" integer[], "user_id" integer NOT NULL, "nfs_store_container_id" integer, "created_at" timestamp, "updated_at" timestamp) ;
ALTER TABLE "nfs_store_move_actions" ADD CONSTRAINT "fk_rails_75138f1972"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "nfs_store_move_actions" ADD CONSTRAINT "fk_rails_c1ea9a5fd9"
FOREIGN KEY ("nfs_store_container_id")
  REFERENCES "nfs_store_containers" ("id")
;


GRANT SELECT, INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT,UPDATE,INSERT,DELETE ON ALL TABLES IN SCHEMA ml_app TO FPHSADM;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSUSR;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO FPHSADM;
SET search_path = ml_app, pg_catalog;
COPY schema_migrations (version) FROM stdin;
20190902123518
20190906172361
\.

 commit; ;
