set search_path=ml_app;
-- Script created @ 2015-09-28 09:24:32 -0400
ALTER TABLE "general_selections" ADD "create_with" boolean;
ALTER TABLE "general_selections" ADD "edit_if_set" boolean;
ALTER TABLE "general_selections" ADD "edit_always" boolean;
ALTER TABLE "general_selections" ADD "position" integer;
ALTER TABLE "general_selections" ADD "description" character varying;
ALTER TABLE "general_selections" ADD "lock" boolean;
