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

create or replace function sync_new_adl_screener() returns trigger
language plpgsql
AS $$
  DECLARE
    matched_master_id INTEGER;
    new_id INTEGER;
  BEGIN

    matched_master_id :=  get_adl_screener_master_id(new.subject_id);


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
      --
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
        household_appliance_other,
        select_household_appliance_performance,
      --
        created_at,
        updated_at
      )
      values
      (
        matched_master_id,
        new.adl_eat,
        new.adl_walk,
        new.adl_toilet,
        new.adl_bath,
        new.adl_groom,
        new.adl_dress_a,
        new.adl_dress_aperf,
        new.adl_dress_b,
        new.adl_phone,
        new.adl_phone_perf,
        new.adl_tv,
        new.adl_tva,
        new.adl_tvb,
        new.adl_tvc,
        new.adl_attnconvo,
        new.adl_attnconvo_part,
        new.adl_dishes,
        new.adl_dishes_perf,
        new.adl_belong,
        new.adl_belong_perf,
        new.adl_beverage,
        new.adl_beverage_perf,
        new.adl_snack,
        new.adl_snack_prep,
        new.adl_garbage,
        new.adl_garbage_perf,
        new.adl_travel,
        new.adl_travel_perf,
        new.adl_shop,
        new.adl_shop_select,
        new.adl_shop_pay,
        new.adl_appt,
        new.adl_appt_aware,
      --  new.institutionalized___1,
        new.adl_alone,
        new.adl_alone_15m,
        new.adl_alone_gt1hr,
        new.adl_alone_lt1hr,
        new.adl_currev,
        new.adl_currev_tv,
        new.adl_currev_outhome,
        new.adl_currev_inhome,
        new.adl_read,
        new.adl_read_lt1hr,
        new.adl_read_gt1hr,
        new.adl_write,
        new.adl_write_complex,
        new.adl_hob,
      --  new.adl_hobls___gam,
      --  new.adl_hobls___bing,
      --  new.adl_hobls___instr,
      --  new.adl_hobls___read,
      --  new.adl_hobls___tenn,
      --  new.adl_hobls___cword,
      --  new.adl_hobls___knit,
      --  new.adl_hobls___gard,
      --  new.adl_hobls___wshop,
      --  new.adl_hobls___art,
      --  new.adl_hobls___sew,
      --  new.adl_hobls___golf,
      --  new.adl_hobls___fish,
      --  new.adl_hobls___oth,
        new.adl_hobls_oth,
        new.adl_hobdc___1,
        new.adl_hob_perf,
        new.adl_appl,
      --  new.adl_applls___wash,
      --  new.adl_applls___dish,
      --  new.adl_applls___range,
      --  new.adl_applls___dry,
      --  new.adl_applls___toast,
      --  new.adl_applls___micro,
      --  new.adl_applls___vac,
      --  new.adl_applls___toven,
      --  new.adl_applls___fproc,
      --  new.adl_applls___oth,
        new.adl_applls_oth,
        new.adl_appl_perf,
      --  new.adl_comm,
        new.adcs_npiq_timestamp,
        now()
      )
      RETURNING id INTO new_id;


    insert into ml_app.model_references
    (from_record_master_id, to_record_type, to_record_id, to_record_master_id, created_at, updated_at)
    values
    (
      matched_master_id, 'DynamicLog::IpaAdlInformantScreener', new_id, matched_master_id, now(), now()
    );


  RETURN NEW;

END;
$$;

CREATE TRIGGER on_adl_screener_data_insert
AFTER INSERT ON adl_screener_data
FOR EACH ROW EXECUTE PROCEDURE sync_new_adl_screener();
