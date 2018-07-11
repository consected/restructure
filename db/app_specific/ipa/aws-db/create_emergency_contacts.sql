
 begin;  ;
CREATE TABLE "emergency_contacts" ("id" serial primary key, "rec_type" character varying,  "data" character varying,  "first_name" character varying, "last_name" character varying, "select_relationship" character varying, "rank" character varying, "user_id" integer, "master_id" integer, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;

CREATE  INDEX  "index_emergency_contacts_on_user_id" ON "emergency_contacts"  ("user_id");
CREATE  INDEX  "index_emergency_contacts_on_master_id" ON "emergency_contacts"  ("master_id");
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "fk_rails_8104b3f11d"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
;
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "fk_rails_f5033c91ed"
FOREIGN KEY ("master_id")
  REFERENCES "masters" ("id")
;

end;
