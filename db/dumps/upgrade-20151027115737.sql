-- Script created @ 2015-10-27 11:57:37 -0400
CREATE TABLE "user_authorizations" ("id" serial primary key, "user_id" integer, "has_authorization" character varying, "admin_id" integer, "disabled" boolean, "created_at" timestamp NOT NULL, "updated_at" timestamp NOT NULL) ;
