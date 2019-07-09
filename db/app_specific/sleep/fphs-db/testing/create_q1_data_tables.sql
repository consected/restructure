create schema if not exists q1 AUTHORIZATION fphs;

create table q1.rc_stage (
  redcap_survey_identifier INTEGER,
  sleephrs INTEGER,
  football_players_health_study_questionnaire_1_timestamp timestamp
);

create table q1.sc_stage (
  msid INTEGER,
  sleephrs INTEGER,
  opp_date timestamp
)
;
