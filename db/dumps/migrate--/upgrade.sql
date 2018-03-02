-- Script created @ 2018-03-02 09:02:19 +0000
set search_path=; 
 begin;  ;
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


 commit; ;
