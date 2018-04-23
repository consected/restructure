-- Script created @ 2018-04-23 11:57:28 +0100
set search_path=ml_app; 
 begin;  ;
CREATE TABLE "schema_migrations" ("version" character varying NOT NULL) ;
CREATE UNIQUE INDEX  "unique_schema_migrations" ON "schema_migrations"  ("version");
CREATE TABLE "masters" ("id" serial primary key) ;
