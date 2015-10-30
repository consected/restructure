-- Script created @ 2015-10-29 12:55:33 -0400
set search_path=public;
begin
ALTER TABLE "dynamic_models" ADD "field_list" character varying;
ALTER TABLE "dynamic_models" ADD "result_order" character varying;

commit;
-- Run on 10/29