# Testing ADL Informant Screener sync

## Redcap to FPHS db sync simulation

The 'internal' database as the source of the screener is `fphs_demo`

To run a simulated sync from redcap to FPHS internal Postgres, do:

    psql -d fphs_demo

    set search_path=ipa_ops;

    \copy ipa_ops.adl_screener_data(record_id,redcap_survey_identifier,adcs_npiq_timestamp,adlnpi_consent___agree,informant,adl_eat,adl_walk,adl_toilet,adl_bath,adl_groom,adl_dressa,adl_dressa_perf,adl_dressb,adl_phone,adl_phone_perf,adl_tv,adl_tva,adl_tvb,adl_tvc,adl_attnconvo,adl_attnconvo_part,adl_dishes,adl_dishes_perf,adl_belong,adl_belong_perf,adl_beverage,adl_beverage_perf,adl_snack,adl_snack_prep,adl_garbage,adl_garbage_perf,adl_travel,adl_travel_perf,adl_shop,adl_shop_select,adl_shop_pay,adl_appt,adl_appt_aware,institutionalized___1,adl_alone,adl_alone_15m,adl_alone_gt1hr,adl_alone_lt1hr,adl_currev,adl_currev_tv,adl_currev_outhome,adl_currev_inhome,adl_read,adl_read_lt1hr,adl_read_gt1hr,adl_write,adl_write_complex,adl_hob,adl_hobls___gam,adl_hobls___bing,adl_hobls___instr,adl_hobls___read,adl_hobls___tenn,adl_hobls___cword,adl_hobls___knit,adl_hobls___gard,adl_hobls___wshop,adl_hobls___art,adl_hobls___sew,adl_hobls___golf,adl_hobls___fish,adl_hobls___oth,adl_hobls_oth,adl_hobdc___1,adl_hob_perf,adl_appl,adl_applls___wash,adl_applls___dish,adl_applls___range,adl_applls___dry,adl_applls___toast,adl_applls___micro,adl_applls___vac,adl_applls___toven,adl_applls___fproc,adl_applls___oth,adl_applls_oth,adl_appl_perf,adl_comm,npi_infor,npi_inforsp,npi_delus,npi_delussev,npi_hallu,npi_hallusev,npi_agita,npi_agitasev,npi_depre,npi_depresev,npi_anxie,npi_anxiesev,npi_elati,npi_elatisev,npi_apath,npi_apathsev,npi_disin,npi_disinsev,npi_irrit,npi_irritsev,npi_motor,npi_motorsev,npi_night,npi_nightsev,npi_appet,npi_appetsev,adcs_npiq_complete) FROM /mnt/laptop-mount/fphs/zeus-with-filestore/db/app_specific/sync-process/ipa-adl-screener-sync/reference-only/download_adl_031220191508.csv WITH (FORMAT CSV, HEADER TRUE);

This will also test the score calculation trigger.

## FPHS db to AWS db sync test

Run the sync process in development to sync the new records from the FPHS internal db to simulated AWS db

    RAILS_ENV=development db/app_specific/sync-process/ipa-adl-screener-sync/scripts/sync_subject_data.sh

Note that records will only be transferred where they have an IPA ID in the destination DB that matches the redcap_survey_identifier in the source DB. In other words, the test data that is copied in the first step probably needs to be manipulated a little to provide some matching IPA IDs.
