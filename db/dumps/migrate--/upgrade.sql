-- Script created @ 2018-02-28 17:48:46 +0000
set search_path=; 
 begin;  ;
CREATE TABLE "emergency_contacts" ("id" serial primary key, "first_name" character varying, "last_name" character varying, "data" character varying, "select_relationship" character varying, "rec_type" character varying, "rank" character varying, "user_id_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
CREATE  INDEX  "index_emergency_contacts_on_user_id_id" ON "emergency_contacts"  ("user_id_id");
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "fk_rails_07831f8c5f"
FOREIGN KEY ("user_id_id")
  REFERENCES "user_ids" ("id")
;


 commit; ;
