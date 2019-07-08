CREATE TABLE sleep.sleep_adl_screener_data
(
id serial NOT NULL,
record_id numeric,
redcap_survey_identifier numeric,
adcs_npiq_timestamp timestamp without time zone,
adlnpi_consent___agree numeric,
informant numeric,
adl_eat numeric,
adl_walk numeric,
adl_toilet numeric,
adl_bath numeric,
adl_groom numeric,
adl_dressa numeric,
adl_dressa_perf numeric,
adl_dressb numeric,
adl_phone numeric,
adl_phone_perf numeric,
adl_tv numeric,
adl_tva numeric,
adl_tvb numeric,
adl_tvc numeric,
adl_attnconvo numeric,
adl_attnconvo_part numeric,
adl_dishes numeric,
adl_dishes_perf numeric,
adl_belong numeric,
adl_belong_perf numeric,
adl_beverage numeric,
adl_beverage_perf numeric,
adl_snack numeric,
adl_snack_prep numeric,
adl_garbage numeric,
adl_garbage_perf numeric,
adl_travel numeric,
adl_travel_perf numeric,
adl_shop numeric,
adl_shop_select numeric,
adl_shop_pay numeric,
adl_appt numeric,
adl_appt_aware numeric,
institutionalized___1 numeric,
adl_alone numeric,
adl_alone_15m numeric,
adl_alone_gt1hr numeric,
adl_alone_lt1hr numeric,
adl_currev numeric,
adl_currev_tv numeric,
adl_currev_outhome numeric,
adl_currev_inhome numeric,
adl_read numeric,
adl_read_lt1hr numeric,
adl_read_gt1hr numeric,
adl_write numeric,
adl_write_complex numeric,
adl_hob numeric,
adl_hobls___gam numeric,
adl_hobls___bing numeric,
adl_hobls___instr numeric,
adl_hobls___read numeric,
adl_hobls___tenn numeric,
adl_hobls___cword numeric,
adl_hobls___knit numeric,
adl_hobls___gard numeric,
adl_hobls___wshop numeric,
adl_hobls___art numeric,
adl_hobls___sew numeric,
adl_hobls___golf numeric,
adl_hobls___fish numeric,
adl_hobls___oth numeric,
adl_hobls_oth text,
adl_hobdc___1 numeric,
adl_hob_perf numeric,
adl_appl numeric,
adl_applls___wash numeric,
adl_applls___dish numeric,
adl_applls___range numeric,
adl_applls___dry numeric,
adl_applls___toast numeric,
adl_applls___micro numeric,
adl_applls___vac numeric,
adl_applls___toven numeric,
adl_applls___fproc numeric,
adl_applls___oth numeric,
adl_applls_oth text,
adl_appl_perf numeric,
adl_comm text,
npi_infor numeric,
npi_inforsp text,
npi_delus numeric,
npi_delussev numeric,
npi_hallu numeric,
npi_hallusev numeric,
npi_agita numeric,
npi_agitasev numeric,
npi_depre numeric,
npi_depresev numeric,
npi_anxie numeric,
npi_anxiesev numeric,
npi_elati numeric,
npi_elatisev numeric,
npi_apath numeric,
npi_apathsev numeric,
npi_disin numeric,
npi_disinsev numeric,
npi_irrit numeric,
npi_irritsev numeric,
npi_motor numeric,
npi_motorsev numeric,
npi_night numeric,
npi_nightsev numeric,
npi_appet numeric,
npi_appetsev numeric,
adcs_npiq_complete numeric,
score numeric,
dk_count numeric,
CONSTRAINT adl_screener_data_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
