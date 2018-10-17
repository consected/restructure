
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_adl_informant_screeners select_regarding_eating select_regarding_walking select_regarding_bowel_and_bladder select_regarding_bathing select_regarding_grooming select_regarding_dressing select_regarding_dressing_performance select_regarding_getting_dressed used_telephone_yes_no_dont_know select_telephone_performance watched_tv_yes_no_dont_know selected_programs_yes_no_dont_know talk_about_content_during_yes_no_dont_know talk_about_content_after_yes_no_dont_know pay_attention_to_conversation_yes_no_dont_know select_degree_of_participation clear_dishes_yes_no_dont_know select_clear_dishes_performance find_personal_belongings_yes_no_dont_know select_find_personal_belongings_performance obtain_beverage_yes_no_dont_know select_obtain_beverage_performance make_meal_yes_no_dont_know select_make_meal_performance dispose_of_garbage_yes_no_dont_know select_dispose_of_garbage_performance get_around_outside_yes_no_dont_know select_get_around_outside_performance go_shopping_yes_no_dont_know select_go_shopping_performance pay_for_items_yes_no_dont_know keep_appointments_yes_no_dont_know select_keep_appointments_performance left_on_own_yes_no_dont_know away_from_home_yes_no_dont_know at_home_more_than_hour_yes_no_dont_know at_home_less_than_hour_yes_no_dont_know talk_about_current_events_yes_no_dont_know did_not_take_part_in_yes_no_dont_know took_part_in_outside_home_yes_no_dont_know took_part_in_at_home_yes_no_dont_know read_yes_no_dont_know talk_about_reading_shortly_after_yes_no_dont_know talk_about_reading_later_yes_no_dont_know write_yes_no_dont_know select_write_performance pastime_yes_no_dont_know multi_select_pastimes pastime_other pastimes_only_at_daycare_no_yes select_pastimes_only_at_daycare_performance use_household_appliance_yes_no_dont_know multi_select_household_appliances household_appliance_other select_household_appliance_performance

      CREATE FUNCTION log_ipa_adl_informant_screener_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_adl_informant_screener_history
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
                      multi_select_pastimes,
                      pastime_other,
                      pastimes_only_at_daycare_no_yes,
                      select_pastimes_only_at_daycare_performance,
                      use_household_appliance_yes_no_dont_know,
                      multi_select_household_appliances,
                      household_appliance_other,
                      select_household_appliance_performance,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_adl_informant_screener_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_regarding_eating,
                      NEW.select_regarding_walking,
                      NEW.select_regarding_bowel_and_bladder,
                      NEW.select_regarding_bathing,
                      NEW.select_regarding_grooming,
                      NEW.select_regarding_dressing,
                      NEW.select_regarding_dressing_performance,
                      NEW.select_regarding_getting_dressed,
                      NEW.used_telephone_yes_no_dont_know,
                      NEW.select_telephone_performance,
                      NEW.watched_tv_yes_no_dont_know,
                      NEW.selected_programs_yes_no_dont_know,
                      NEW.talk_about_content_during_yes_no_dont_know,
                      NEW.talk_about_content_after_yes_no_dont_know,
                      NEW.pay_attention_to_conversation_yes_no_dont_know,
                      NEW.select_degree_of_participation,
                      NEW.clear_dishes_yes_no_dont_know,
                      NEW.select_clear_dishes_performance,
                      NEW.find_personal_belongings_yes_no_dont_know,
                      NEW.select_find_personal_belongings_performance,
                      NEW.obtain_beverage_yes_no_dont_know,
                      NEW.select_obtain_beverage_performance,
                      NEW.make_meal_yes_no_dont_know,
                      NEW.select_make_meal_performance,
                      NEW.dispose_of_garbage_yes_no_dont_know,
                      NEW.select_dispose_of_garbage_performance,
                      NEW.get_around_outside_yes_no_dont_know,
                      NEW.select_get_around_outside_performance,
                      NEW.go_shopping_yes_no_dont_know,
                      NEW.select_go_shopping_performance,
                      NEW.pay_for_items_yes_no_dont_know,
                      NEW.keep_appointments_yes_no_dont_know,
                      NEW.select_keep_appointments_performance,
                      NEW.left_on_own_yes_no_dont_know,
                      NEW.away_from_home_yes_no_dont_know,
                      NEW.at_home_more_than_hour_yes_no_dont_know,
                      NEW.at_home_less_than_hour_yes_no_dont_know,
                      NEW.talk_about_current_events_yes_no_dont_know,
                      NEW.did_not_take_part_in_yes_no_dont_know,
                      NEW.took_part_in_outside_home_yes_no_dont_know,
                      NEW.took_part_in_at_home_yes_no_dont_know,
                      NEW.read_yes_no_dont_know,
                      NEW.talk_about_reading_shortly_after_yes_no_dont_know,
                      NEW.talk_about_reading_later_yes_no_dont_know,
                      NEW.write_yes_no_dont_know,
                      NEW.select_write_performance,
                      NEW.pastime_yes_no_dont_know,
                      NEW.multi_select_pastimes,
                      NEW.pastime_other,
                      NEW.pastimes_only_at_daycare_no_yes,
                      NEW.select_pastimes_only_at_daycare_performance,
                      NEW.use_household_appliance_yes_no_dont_know,
                      NEW.multi_select_household_appliances,
                      NEW.household_appliance_other,
                      NEW.select_household_appliance_performance,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_adl_informant_screener_history (
          id integer NOT NULL,
          master_id integer,
          select_regarding_eating varchar,
          select_regarding_walking varchar,
          select_regarding_bowel_and_bladder varchar,
          select_regarding_bathing varchar,
          select_regarding_grooming varchar,
          select_regarding_dressing varchar,
          select_regarding_dressing_performance varchar,
          select_regarding_getting_dressed varchar,
          used_telephone_yes_no_dont_know varchar,
          select_telephone_performance varchar,
          watched_tv_yes_no_dont_know varchar,
          selected_programs_yes_no_dont_know varchar,
          talk_about_content_during_yes_no_dont_know varchar,
          talk_about_content_after_yes_no_dont_know varchar,
          pay_attention_to_conversation_yes_no_dont_know varchar,
          select_degree_of_participation varchar,
          clear_dishes_yes_no_dont_know varchar,
          select_clear_dishes_performance varchar,
          find_personal_belongings_yes_no_dont_know varchar,
          select_find_personal_belongings_performance varchar,
          obtain_beverage_yes_no_dont_know varchar,
          select_obtain_beverage_performance varchar,
          make_meal_yes_no_dont_know varchar,
          select_make_meal_performance varchar,
          dispose_of_garbage_yes_no_dont_know varchar,
          select_dispose_of_garbage_performance varchar,
          get_around_outside_yes_no_dont_know varchar,
          select_get_around_outside_performance varchar,
          go_shopping_yes_no_dont_know varchar,
          select_go_shopping_performance varchar,
          pay_for_items_yes_no_dont_know varchar,
          keep_appointments_yes_no_dont_know varchar,
          select_keep_appointments_performance varchar,
          left_on_own_yes_no_dont_know varchar,
          away_from_home_yes_no_dont_know varchar,
          at_home_more_than_hour_yes_no_dont_know varchar,
          at_home_less_than_hour_yes_no_dont_know varchar,
          talk_about_current_events_yes_no_dont_know varchar,
          did_not_take_part_in_yes_no_dont_know varchar,
          took_part_in_outside_home_yes_no_dont_know varchar,
          took_part_in_at_home_yes_no_dont_know varchar,
          read_yes_no_dont_know varchar,
          talk_about_reading_shortly_after_yes_no_dont_know varchar,
          talk_about_reading_later_yes_no_dont_know varchar,
          write_yes_no_dont_know varchar,
          select_write_performance varchar,
          pastime_yes_no_dont_know varchar,
          multi_select_pastimes varchar[],
          pastime_other varchar,
          pastimes_only_at_daycare_no_yes varchar,
          select_pastimes_only_at_daycare_performance varchar,
          use_household_appliance_yes_no_dont_know varchar,
          multi_select_household_appliances varchar[],
          household_appliance_other varchar,
          select_household_appliance_performance varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_adl_informant_screener_id integer
      );

      CREATE SEQUENCE ipa_adl_informant_screener_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_adl_informant_screener_history_id_seq OWNED BY ipa_adl_informant_screener_history.id;

      CREATE TABLE ipa_adl_informant_screeners (
          id integer NOT NULL,
          master_id integer,
          select_regarding_eating varchar,
          select_regarding_walking varchar,
          select_regarding_bowel_and_bladder varchar,
          select_regarding_bathing varchar,
          select_regarding_grooming varchar,
          select_regarding_dressing varchar,
          select_regarding_dressing_performance varchar,
          select_regarding_getting_dressed varchar,
          used_telephone_yes_no_dont_know varchar,
          select_telephone_performance varchar,
          watched_tv_yes_no_dont_know varchar,
          selected_programs_yes_no_dont_know varchar,
          talk_about_content_during_yes_no_dont_know varchar,
          talk_about_content_after_yes_no_dont_know varchar,
          pay_attention_to_conversation_yes_no_dont_know varchar,
          select_degree_of_participation varchar,
          clear_dishes_yes_no_dont_know varchar,
          select_clear_dishes_performance varchar,
          find_personal_belongings_yes_no_dont_know varchar,
          select_find_personal_belongings_performance varchar,
          obtain_beverage_yes_no_dont_know varchar,
          select_obtain_beverage_performance varchar,
          make_meal_yes_no_dont_know varchar,
          select_make_meal_performance varchar,
          dispose_of_garbage_yes_no_dont_know varchar,
          select_dispose_of_garbage_performance varchar,
          get_around_outside_yes_no_dont_know varchar,
          select_get_around_outside_performance varchar,
          go_shopping_yes_no_dont_know varchar,
          select_go_shopping_performance varchar,
          pay_for_items_yes_no_dont_know varchar,
          keep_appointments_yes_no_dont_know varchar,
          select_keep_appointments_performance varchar,
          left_on_own_yes_no_dont_know varchar,
          away_from_home_yes_no_dont_know varchar,
          at_home_more_than_hour_yes_no_dont_know varchar,
          at_home_less_than_hour_yes_no_dont_know varchar,
          talk_about_current_events_yes_no_dont_know varchar,
          did_not_take_part_in_yes_no_dont_know varchar,
          took_part_in_outside_home_yes_no_dont_know varchar,
          took_part_in_at_home_yes_no_dont_know varchar,
          read_yes_no_dont_know varchar,
          talk_about_reading_shortly_after_yes_no_dont_know varchar,
          talk_about_reading_later_yes_no_dont_know varchar,
          write_yes_no_dont_know varchar,
          select_write_performance varchar,
          pastime_yes_no_dont_know varchar,
          multi_select_pastimes varchar[],
          pastime_other varchar,
          pastimes_only_at_daycare_no_yes varchar,
          select_pastimes_only_at_daycare_performance varchar,
          use_household_appliance_yes_no_dont_know varchar,
          multi_select_household_appliances varchar[],
          household_appliance_other varchar,
          select_household_appliance_performance varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_adl_informant_screeners_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_adl_informant_screeners_id_seq OWNED BY ipa_adl_informant_screeners.id;

      ALTER TABLE ONLY ipa_adl_informant_screeners ALTER COLUMN id SET DEFAULT nextval('ipa_adl_informant_screeners_id_seq'::regclass);
      ALTER TABLE ONLY ipa_adl_informant_screener_history ALTER COLUMN id SET DEFAULT nextval('ipa_adl_informant_screener_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_adl_informant_screener_history
          ADD CONSTRAINT ipa_adl_informant_screener_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_adl_informant_screeners
          ADD CONSTRAINT ipa_adl_informant_screeners_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_adl_informant_screener_history_on_master_id ON ipa_adl_informant_screener_history USING btree (master_id);


      CREATE INDEX index_ipa_adl_informant_screener_history_on_ipa_adl_informant_screener_id ON ipa_adl_informant_screener_history USING btree (ipa_adl_informant_screener_id);
      CREATE INDEX index_ipa_adl_informant_screener_history_on_user_id ON ipa_adl_informant_screener_history USING btree (user_id);

      CREATE INDEX index_ipa_adl_informant_screeners_on_master_id ON ipa_adl_informant_screeners USING btree (master_id);

      CREATE INDEX index_ipa_adl_informant_screeners_on_user_id ON ipa_adl_informant_screeners USING btree (user_id);

      CREATE TRIGGER ipa_adl_informant_screener_history_insert AFTER INSERT ON ipa_adl_informant_screeners FOR EACH ROW EXECUTE PROCEDURE log_ipa_adl_informant_screener_update();
      CREATE TRIGGER ipa_adl_informant_screener_history_update AFTER UPDATE ON ipa_adl_informant_screeners FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_adl_informant_screener_update();


      ALTER TABLE ONLY ipa_adl_informant_screeners
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_adl_informant_screeners
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_adl_informant_screener_history
          ADD CONSTRAINT fk_ipa_adl_informant_screener_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_adl_informant_screener_history
          ADD CONSTRAINT fk_ipa_adl_informant_screener_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_adl_informant_screener_history
          ADD CONSTRAINT fk_ipa_adl_informant_screener_history_ipa_adl_informant_screeners FOREIGN KEY (ipa_adl_informant_screener_id) REFERENCES ipa_adl_informant_screeners(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
