
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_tms_tests false 


-- Field order:
-- past_tms_blank_yes_no_dont_know, past_tms_details, convulsion_or_seizue_blank_yes_no_dont_know, epilepsy_blank_yes_no_dont_know, fainting_blank_yes_no_dont_know, concussion_blank_yes_no_dont_know,
-- loss_of_conciousness_details, hearing_problems_blank_yes_no_dont_know, cochlear_implants_blank_yes_no_dont_know, neurostimulator_details, neurostimulator_blank_yes_no_dont_know,
-- med_infusion_device_blank_yes_no_dont_know, med_infusion_device_details, metal_blank_yes_no_dont_know, metal_details, current_meds_blank_yes_no_dont_know, current_meds_details,
-- other_chronic_problems_blank_yes_no_dont_know, other_chronic_problems_details, hospital_visits_blank_yes_no_dont_know, hospital_visits_details,
-- dietary_restrictions_blank_yes_no_dont_know, dietary_restrictions_details, anything_else_blank_yes_no, anything_else_details,
--


        CREATE or replace FUNCTION log_ipa_ps_tms_test_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_tms_test_history
                  (
                      master_id,
                      convulsion_or_seizure_blank_yes_no_dont_know,
                      epilepsy_blank_yes_no_dont_know,
                      fainting_blank_yes_no_dont_know,
                      concussion_blank_yes_no_dont_know,
                      loss_of_conciousness_details,
                      hearing_problems_blank_yes_no_dont_know,
                      cochlear_implants_blank_yes_no_dont_know,
                      metal_blank_yes_no_dont_know,
                      metal_details,
                      neurostimulator_blank_yes_no_dont_know,
                      neurostimulator_details,
                      med_infusion_device_blank_yes_no_dont_know,
                      med_infusion_device_details,
                      past_tms_blank_yes_no_dont_know,
                      past_tms_details,
                      current_meds_blank_yes_no_dont_know,
                      current_meds_details,
                      other_chronic_problems_blank_yes_no_dont_know,
                      other_chronic_problems_details,
                      hospital_visits_blank_yes_no_dont_know,
                      hospital_visits_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      anything_else_blank_yes_no,
                      anything_else_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_tms_test_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.convulsion_or_seizure_blank_yes_no_dont_know,
                      NEW.epilepsy_blank_yes_no_dont_know,
                      NEW.fainting_blank_yes_no_dont_know,
                      NEW.concussion_blank_yes_no_dont_know,
                      NEW.loss_of_conciousness_details,
                      NEW.hearing_problems_blank_yes_no_dont_know,
                      NEW.cochlear_implants_blank_yes_no_dont_know,
                      NEW.metal_blank_yes_no_dont_know,
                      NEW.metal_details,
                      NEW.neurostimulator_blank_yes_no_dont_know,
                      NEW.neurostimulator_details,
                      NEW.med_infusion_device_blank_yes_no_dont_know,
                      NEW.med_infusion_device_details,
                      NEW.past_tms_blank_yes_no_dont_know,
                      NEW.past_tms_details,
                      NEW.current_meds_blank_yes_no_dont_know,
                      NEW.current_meds_details,
                      NEW.other_chronic_problems_blank_yes_no_dont_know,
                      NEW.other_chronic_problems_details,
                      NEW.hospital_visits_blank_yes_no_dont_know,
                      NEW.hospital_visits_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.anything_else_blank_yes_no,
                      NEW.anything_else_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_tms_test_history (
          id integer NOT NULL,
          master_id integer,
          convulsion_or_seizure_blank_yes_no_dont_know varchar,
          epilepsy_blank_yes_no_dont_know varchar,
          fainting_blank_yes_no_dont_know varchar,
          concussion_blank_yes_no_dont_know varchar,
          loss_of_conciousness_details varchar,
          hearing_problems_blank_yes_no_dont_know varchar,
          cochlear_implants_blank_yes_no_dont_know varchar,
          metal_blank_yes_no_dont_know varchar,
          metal_details varchar,
          neurostimulator_blank_yes_no_dont_know varchar,
          neurostimulator_details varchar,
          -- pacemaker_blank_yes_no_dont_know varchar,
          med_infusion_device_blank_yes_no_dont_know varchar,
          med_infusion_device_details varchar,
          past_tms_blank_yes_no_dont_know varchar,
          past_tms_details varchar,
          -- past_mri_blank_yes_no_dont_know varchar,
          -- past_mri_details varchar,
          current_meds_blank_yes_no_dont_know varchar,
          current_meds_details varchar,
          -- neuro_history_details varchar,
          other_chronic_problems_blank_yes_no_dont_know varchar,
          other_chronic_problems_details varchar,
          hospital_visits_blank_yes_no_dont_know varchar,
          hospital_visits_details varchar,
          dietary_restrictions_blank_yes_no_dont_know varchar,
          dietary_restrictions_details varchar,
          anything_else_blank_yes_no varchar,
          anything_else_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_tms_test_id integer
      );

      CREATE SEQUENCE ipa_ps_tms_test_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_tms_test_history_id_seq OWNED BY ipa_ps_tms_test_history.id;

      CREATE TABLE ipa_ps_tms_tests (
          id integer NOT NULL,
          master_id integer,
          convulsion_or_seizure_blank_yes_no_dont_know varchar,
          epilepsy_blank_yes_no_dont_know varchar,
          fainting_blank_yes_no_dont_know varchar,
          concussion_blank_yes_no_dont_know varchar,
          loss_of_conciousness_details varchar,
          hearing_problems_blank_yes_no_dont_know varchar,
          cochlear_implants_blank_yes_no_dont_know varchar,
          metal_blank_yes_no_dont_know varchar,
          metal_details varchar,
          neurostimulator_blank_yes_no_dont_know varchar,
          neurostimulator_details varchar,
          -- pacemaker_blank_yes_no_dont_know varchar,
          med_infusion_device_blank_yes_no_dont_know varchar,
          med_infusion_device_details varchar,
          past_tms_blank_yes_no_dont_know varchar,
          past_tms_details varchar,
          -- past_mri_blank_yes_no_dont_know varchar,
          -- past_mri_details varchar,
          current_meds_blank_yes_no_dont_know varchar,
          current_meds_details varchar,
          -- neuro_history_details varchar,
          other_chronic_problems_blank_yes_no_dont_know varchar,
          other_chronic_problems_details varchar,
          hospital_visits_blank_yes_no_dont_know varchar,
          hospital_visits_details varchar,
          dietary_restrictions_blank_yes_no_dont_know varchar,
          dietary_restrictions_details varchar,
          anything_else_blank_yes_no varchar,
          anything_else_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_tms_tests_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_tms_tests_id_seq OWNED BY ipa_ps_tms_tests.id;

      ALTER TABLE ONLY ipa_ps_tms_tests ALTER COLUMN id SET DEFAULT nextval('ipa_ps_tms_tests_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_tms_test_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_tms_test_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_tms_test_history
          ADD CONSTRAINT ipa_ps_tms_test_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_tms_tests
          ADD CONSTRAINT ipa_ps_tms_tests_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_tms_test_history_on_master_id ON ipa_ps_tms_test_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_tms_test_history_on_ipa_ps_tms_test_id ON ipa_ps_tms_test_history USING btree (ipa_ps_tms_test_id);
      CREATE INDEX index_ipa_ps_tms_test_history_on_user_id ON ipa_ps_tms_test_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_tms_tests_on_master_id ON ipa_ps_tms_tests USING btree (master_id);

      CREATE INDEX index_ipa_ps_tms_tests_on_user_id ON ipa_ps_tms_tests USING btree (user_id);

      CREATE TRIGGER ipa_ps_tms_test_history_insert AFTER INSERT ON ipa_ps_tms_tests FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_tms_test_update();
      CREATE TRIGGER ipa_ps_tms_test_history_update AFTER UPDATE ON ipa_ps_tms_tests FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_tms_test_update();


      ALTER TABLE ONLY ipa_ps_tms_tests
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_tms_tests
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_tms_test_history
          ADD CONSTRAINT fk_ipa_ps_tms_test_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_tms_test_history
          ADD CONSTRAINT fk_ipa_ps_tms_test_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_tms_test_history
          ADD CONSTRAINT fk_ipa_ps_tms_test_history_ipa_ps_tms_tests FOREIGN KEY (ipa_ps_tms_test_id) REFERENCES ipa_ps_tms_tests(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
