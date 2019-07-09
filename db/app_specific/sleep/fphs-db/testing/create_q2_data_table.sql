create schema if not exists q2 AUTHORIZATION fphs;

create table q2.q2_data_sleep (
  redcap_survey_identifier INTEGER,
  phq3 INTEGER,
  stpbng_tired INTEGER,
  bpi9f INTEGER
);
