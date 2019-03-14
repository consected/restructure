CREATE OR REPLACE FUNCTION get_adl_screener_master_id(subject_id INTEGER) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  matched_master_id INTEGER;
BEGIN


		SELECT ipa.master_id
    INTO matched_master_id
		FROM ml_app.masters m
		INNER JOIN ipa_ops.ipa_assignments ipa
			ON m.id = ipa.master_id
		WHERE
      ipa.ipa_id = subject_id
    LIMIT 1
		;

    RETURN matched_master_id;
END;
$$;

create or replace function ipa_ops.sync_new_adl_screener() returns trigger
language plpgsql
AS $$
  DECLARE
    matched_master_id INTEGER;
    new_id INTEGER;
  BEGIN

    matched_master_id :=  get_adl_screener_master_id(new.redcap_survey_identifier);


    insert into ipa_adl_informant_screeners
      (
        master_id,
        select_regarding_eating,
        select_regarding_walking,
        select_regarding_bowel_and_bladder,
        select_regarding_bathing,
        select_regarding_grooming,
        select_regarding_dressing,
        select_regarding_dressing_performance,
        select_regarding_getting_dressed,
        used_telephone_yes_no_dont_know,
        select_telephone_performance,
        watched_tv_yes_no_dont_know,
        selected_programs_yes_no_dont_know,
        talk_about_content_during_yes_no_dont_know,
        talk_about_content_after_yes_no_dont_know,
        pay_attention_to_conversation_yes_no_dont_know,
        select_degree_of_participation,
        clear_dishes_yes_no_dont_know,
        select_clear_dishes_performance,
        find_personal_belongings_yes_no_dont_know,
        select_find_personal_belongings_performance,
        obtain_beverage_yes_no_dont_know,
        select_obtain_beverage_performance,
        make_meal_yes_no_dont_know,
        select_make_meal_performance,
        dispose_of_garbage_yes_no_dont_know,
        select_dispose_of_garbage_performance,
        get_around_outside_yes_no_dont_know,
        select_get_around_outside_performance,
        go_shopping_yes_no_dont_know,
        select_go_shopping_performance,
        pay_for_items_yes_no_dont_know,
        keep_appointments_yes_no_dont_know,
        select_keep_appointments_performance,
        institutionalized_no_yes,
        left_on_own_yes_no_dont_know,
        away_from_home_yes_no_dont_know,
        at_home_more_than_hour_yes_no_dont_know,
        at_home_less_than_hour_yes_no_dont_know,
        talk_about_current_events_yes_no_dont_know,
        did_not_take_part_in_yes_no_dont_know,
        took_part_in_outside_home_yes_no_dont_know,
        took_part_in_at_home_yes_no_dont_know,
        read_yes_no_dont_know,
        talk_about_reading_shortly_after_yes_no_dont_know,
        talk_about_reading_later_yes_no_dont_know,
        write_yes_no_dont_know,
        select_write_performance,
        pastime_yes_no_dont_know,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
      --  multi_select_pastimes,
        multi_select_pastimes,

        pastime_other,
        pastimes_only_at_daycare_no_yes,
        select_pastimes_only_at_daycare_performance,
        use_household_appliance_yes_no_dont_know,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
      --  multi_select_household_appliances,
        multi_select_household_appliances,
        household_appliance_other,
        select_household_appliance_performance,


        npi_infor,
        npi_inforsp,
        npi_delus,
        npi_delussev,
        npi_hallu,
        npi_hallusev,
        npi_agita,
        npi_agitasev,
        npi_depre,
        npi_depresev,
        npi_anxie,
        npi_anxiesev,
        npi_elati,
        npi_elatisev,
        npi_apath,
        npi_apathsev,
        npi_disin,
        npi_disinsev,
        npi_irrit,
        npi_irritsev,
        npi_motor,
        npi_motorsev,
        npi_night,
        npi_nightsev,
        npi_appet,
        npi_appetsev,

      --
        created_at,
        updated_at
      )
      values
      (
        matched_master_id,
        NEW.adl_eat,
        NEW.adl_walk,
        NEW.adl_toilet,
        NEW.adl_bath,
        NEW.adl_groom,
        NEW.adl_dressa,
        NEW.adl_dressa_perf,
        NEW.adl_dressb,
        CASE WHEN NEW.adl_phone = 0 THEN 'no' WHEN NEW.adl_phone = 1 THEN 'yes' WHEN NEW.adl_phone = 9 THEN 'don''t know' ELSE NEW.adl_phone::varchar END,
        NEW.adl_phone_perf,
        CASE WHEN NEW.adl_tv = 0 THEN 'no' WHEN NEW.adl_tv = 1 THEN 'yes' WHEN NEW.adl_tv = 9 THEN 'don''t know' ELSE NEW.adl_tv::varchar END,
        CASE WHEN NEW.adl_tva = 0 THEN 'no' WHEN NEW.adl_tva = 1 THEN 'yes' WHEN NEW.adl_tva = 9 THEN 'don''t know' ELSE NEW.adl_tva::varchar END,
        CASE WHEN NEW.adl_tvb = 0 THEN 'no' WHEN NEW.adl_tvb = 1 THEN 'yes' WHEN NEW.adl_tvb = 9 THEN 'don''t know' ELSE NEW.adl_tvb::varchar END,
        CASE WHEN NEW.adl_tvc = 0 THEN 'no' WHEN NEW.adl_tvc = 1 THEN 'yes' WHEN NEW.adl_tvc = 9 THEN 'don''t know' ELSE NEW.adl_tvc::varchar END,
        CASE WHEN NEW.adl_attnconvo = 0 THEN 'no' WHEN NEW.adl_attnconvo = 1 THEN 'yes' WHEN NEW.adl_attnconvo = 9 THEN 'don''t know' ELSE NEW.adl_attnconvo::varchar END,
        NEW.adl_attnconvo_part,
        CASE WHEN NEW.adl_dishes = 0 THEN 'no' WHEN NEW.adl_dishes = 1 THEN 'yes' WHEN NEW.adl_dishes = 9 THEN 'don''t know' ELSE NEW.adl_dishes::varchar END,
        NEW.adl_dishes_perf,
        CASE WHEN NEW.adl_belong = 0 THEN 'no' WHEN NEW.adl_belong = 1 THEN 'yes' WHEN NEW.adl_belong = 9 THEN 'don''t know' ELSE NEW.adl_belong::varchar END,
        NEW.adl_belong_perf,
        CASE WHEN NEW.adl_beverage = 0 THEN 'no' WHEN NEW.adl_beverage = 1 THEN 'yes' WHEN NEW.adl_beverage = 9 THEN 'don''t know' ELSE NEW.adl_beverage::varchar END,
        NEW.adl_beverage_perf,
        CASE WHEN NEW.adl_snack = 0 THEN 'no' WHEN NEW.adl_snack = 1 THEN 'yes' WHEN NEW.adl_snack = 9 THEN 'don''t know' ELSE NEW.adl_snack::varchar END,
        NEW.adl_snack_prep,
        CASE WHEN NEW.adl_garbage = 0 THEN 'no' WHEN NEW.adl_garbage = 1 THEN 'yes' WHEN NEW.adl_garbage = 9 THEN 'don''t know' ELSE NEW.adl_garbage::varchar END,
        NEW.adl_garbage_perf,
        CASE WHEN NEW.adl_travel = 0 THEN 'no' WHEN NEW.adl_travel = 1 THEN 'yes' WHEN NEW.adl_travel = 9 THEN 'don''t know' ELSE NEW.adl_travel::varchar END,
        NEW.adl_travel_perf,
        CASE WHEN NEW.adl_shop = 0 THEN 'no' WHEN NEW.adl_shop = 1 THEN 'yes' WHEN NEW.adl_shop = 9 THEN 'don''t know' ELSE NEW.adl_shop::varchar END,
        NEW.adl_shop_select,
        CASE WHEN NEW.adl_shop_pay = 0 THEN 'no' WHEN NEW.adl_shop_pay = 1 THEN 'yes' WHEN NEW.adl_shop_pay = 9 THEN 'don''t know' ELSE NEW.adl_shop_pay::varchar END,
        CASE WHEN NEW.adl_appt = 0 THEN 'no' WHEN NEW.adl_appt = 1 THEN 'yes' WHEN NEW.adl_appt = 9 THEN 'don''t know' ELSE NEW.adl_appt::varchar END,
        NEW.adl_appt_aware,
        CASE WHEN NEW.institutionalized___1 = 0 THEN 'no' WHEN NEW.institutionalized___1 = 1 THEN 'yes' WHEN NEW.institutionalized___1 = 9 THEN 'don''t know' ELSE NEW.institutionalized___1::varchar END,
        CASE WHEN NEW.adl_alone = 0 THEN 'no' WHEN NEW.adl_alone = 1 THEN 'yes' WHEN NEW.adl_alone = 9 THEN 'don''t know' ELSE NEW.adl_alone::varchar END,
        CASE WHEN NEW.adl_alone_15m = 0 THEN 'no' WHEN NEW.adl_alone_15m = 1 THEN 'yes' WHEN NEW.adl_alone_15m = 9 THEN 'don''t know' ELSE NEW.adl_alone_15m::varchar END,
        CASE WHEN NEW.adl_alone_gt1hr = 0 THEN 'no' WHEN NEW.adl_alone_gt1hr = 1 THEN 'yes' WHEN NEW.adl_alone_gt1hr = 9 THEN 'don''t know' ELSE NEW.adl_alone_gt1hr::varchar END,
        CASE WHEN NEW.adl_alone_lt1hr = 0 THEN 'no' WHEN NEW.adl_alone_lt1hr = 1 THEN 'yes' WHEN NEW.adl_alone_lt1hr = 9 THEN 'don''t know' ELSE NEW.adl_alone_lt1hr::varchar END,
        CASE WHEN NEW.adl_currev = 0 THEN 'no' WHEN NEW.adl_currev = 1 THEN 'yes' WHEN NEW.adl_currev = 9 THEN 'don''t know' ELSE NEW.adl_currev::varchar END,
        CASE WHEN NEW.adl_currev_tv = 0 THEN 'no' WHEN NEW.adl_currev_tv = 1 THEN 'yes' WHEN NEW.adl_currev_tv = 9 THEN 'don''t know' ELSE NEW.adl_currev_tv::varchar END,
        CASE WHEN NEW.adl_currev_outhome = 0 THEN 'no' WHEN NEW.adl_currev_outhome = 1 THEN 'yes' WHEN NEW.adl_currev_outhome = 9 THEN 'don''t know' ELSE NEW.adl_currev_outhome::varchar END,
        CASE WHEN NEW.adl_currev_inhome = 0 THEN 'no' WHEN NEW.adl_currev_inhome = 1 THEN 'yes' WHEN NEW.adl_currev_inhome = 9 THEN 'don''t know' ELSE NEW.adl_currev_inhome::varchar END,
        CASE WHEN NEW.adl_read = 0 THEN 'no' WHEN NEW.adl_read = 1 THEN 'yes' WHEN NEW.adl_read = 9 THEN 'don''t know' ELSE NEW.adl_read::varchar END,
        CASE WHEN NEW.adl_read_lt1hr = 0 THEN 'no' WHEN NEW.adl_read_lt1hr = 1 THEN 'yes' WHEN NEW.adl_read_lt1hr = 9 THEN 'don''t know' ELSE NEW.adl_read_lt1hr::varchar END,
        CASE WHEN NEW.adl_read_gt1hr = 0 THEN 'no' WHEN NEW.adl_read_gt1hr = 1 THEN 'yes' WHEN NEW.adl_read_gt1hr = 9 THEN 'don''t know' ELSE NEW.adl_read_gt1hr::varchar END,
        CASE WHEN NEW.adl_write = 0 THEN 'no' WHEN NEW.adl_write = 1 THEN 'yes' WHEN NEW.adl_write = 9 THEN 'don''t know' ELSE NEW.adl_write::varchar END,
        NEW.adl_write_complex,
        CASE WHEN NEW.adl_hob = 0 THEN 'no' WHEN NEW.adl_hob = 1 THEN 'yes' WHEN NEW.adl_hob = 9 THEN 'don''t know' ELSE NEW.adl_hob::varchar END,
        --  adl_hobls___gam,
        --  adl_hobls___bing,
        --  adl_hobls___instr,
        --  adl_hobls___read,
        --  adl_hobls___tenn,
        --  adl_hobls___cword,
        --  adl_hobls___knit,
        --  adl_hobls___gard,
        --  adl_hobls___wshop,
        --  adl_hobls___art,
        --  adl_hobls___sew,
        --  adl_hobls___golf,
        --  adl_hobls___fish,
        --  adl_hobls___oth,
        array[NEW.adl_hobls___gam , NEW.adl_hobls___bing, NEW.adl_hobls___instr, NEW.adl_hobls___read, NEW.adl_hobls___tenn, NEW.adl_hobls___cword, NEW.adl_hobls___knit, NEW.adl_hobls___gard, NEW.adl_hobls___wshop, NEW.adl_hobls___art, NEW.adl_hobls___sew, NEW.adl_hobls___golf, NEW.adl_hobls___fish, NEW.adl_hobls___oth ],

        NEW.adl_hobls_oth,
        CASE WHEN NEW.adl_hobdc___1 = 0 THEN 'no' WHEN NEW.adl_hobdc___1 = 1 THEN 'yes' WHEN NEW.adl_hobdc___1 = 9 THEN 'don''t know' ELSE NEW.adl_hobdc___1::varchar END,
        NEW.adl_hob_perf,
        CASE WHEN NEW.adl_appl = 0 THEN 'no' WHEN NEW.adl_appl = 1 THEN 'yes' WHEN NEW.adl_appl = 9 THEN 'don''t know' ELSE NEW.adl_appl::varchar END,
        array[NEW.adl_applls___wash,  NEW.adl_applls___dish, NEW.adl_applls___range, NEW.adl_applls___dry, NEW.adl_applls___toast, NEW.adl_applls___micro, NEW.adl_applls___vac, NEW.adl_applls___toven, NEW.adl_applls___fproc, NEW.adl_applls___oth],
        --  adl_applls___wash,
        --  adl_applls___dish,
        --  adl_applls___range,
        --  adl_applls___dry,
        --  adl_applls___toast,
        --  adl_applls___micro,
        --  adl_applls___vac,
        --  adl_applls___toven,
        --  adl_applls___fproc,
        --  adl_applls___oth,
        NEW.adl_applls_oth,
        NEW.adl_appl_perf,
        --  adl_comm,

        NEW.npi_infor,
        NEW.npi_inforsp,
        NEW.npi_delus,
        NEW.npi_delussev,
        NEW.npi_hallu,
        NEW.npi_hallusev,
        NEW.npi_agita,
        NEW.npi_agitasev,
        NEW.npi_depre,
        NEW.npi_depresev,
        NEW.npi_anxie,
        NEW.npi_anxiesev,
        NEW.npi_elati,
        NEW.npi_elatisev,
        NEW.npi_apath,
        NEW.npi_apathsev,
        NEW.npi_disin,
        NEW.npi_disinsev,
        NEW.npi_irrit,
        NEW.npi_irritsev,
        NEW.npi_motor,
        NEW.npi_motorsev,
        NEW.npi_night,
        NEW.npi_nightsev,
        NEW.npi_appet,
        NEW.npi_appetsev,



        NEW.adcs_npiq_timestamp,
        now()
      )
      RETURNING id INTO new_id;

    insert into activity_log_ipa_assignment_inex_checklists
    (master_id, extra_log_type, created_at, updated_at)
    values
    (
      matched_master_id, 'adl_informant_screener', now(), now()
    );

    insert into ml_app.model_references
    (from_record_master_id, to_record_type, to_record_id, to_record_master_id, created_at, updated_at)
    values
    (
      matched_master_id, 'DynamicModel::IpaAdlInformantScreener', new_id, matched_master_id, now(), now()
    );


  RETURN NEW;

END;
$$;

CREATE TRIGGER on_adl_screener_data_insert
AFTER INSERT ON adl_screener_data
FOR EACH ROW EXECUTE PROCEDURE sync_new_adl_screener();
