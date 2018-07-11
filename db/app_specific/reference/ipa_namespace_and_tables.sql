create schema ipa_ops;

create table ipa_ops.subjects (
  id SERIAL,
  master_id integer,
  pilot_id integer);
