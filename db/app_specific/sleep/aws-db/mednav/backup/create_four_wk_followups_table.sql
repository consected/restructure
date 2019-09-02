set search_path=sleep,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_four_wk_followups select_all_results_returned select_sensory_testing_returned sensory_testing_notes select_liver_mri_returned liver_mri_notes select_physical_function_returned physical_function_notes select_sleep_returned sleep_notes select_cardiology_returned cardiology_notes select_xray_returned xray_notes assisted_finding_provider_yes_no assistance_notes other_notes

      CREATE or REPLACE FUNCTION log_sleep_four_wk_followup_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_four_wk_followup_history
                  (
                      master_id,
                      select_all_results_returned,
                      select_sensory_testing_returned,
                      sensory_testing_notes,
                      select_liver_mri_returned,
                      liver_mri_notes,
                      select_physical_function_returned,
                      physical_function_notes,
                      select_eeg_returned,
                      eeg_notes,
                      select_sleep_returned,
                      sleep_notes,
                      select_cardiology_returned,
                      cardiology_notes,
                      select_xray_returned,
                      xray_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_four_wk_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_all_results_returned,
                      NEW.select_sensory_testing_returned,
                      NEW.sensory_testing_notes,
                      NEW.select_liver_mri_returned,
                      NEW.liver_mri_notes,
                      NEW.select_physical_function_returned,
                      NEW.physical_function_notes,
                      NEW.select_eeg_returned,
                      NEW.eeg_notes,
                      NEW.select_sleep_returned,
                      NEW.sleep_notes,
                      NEW.select_cardiology_returned,
                      NEW.cardiology_notes,
                      NEW.select_xray_returned,
                      NEW.xray_notes,
                      NEW.assisted_finding_provider_yes_no,
                      NEW.assistance_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_four_wk_followup_history (
          id integer NOT NULL,
          master_id integer,
          select_all_results_returned varchar,
          select_sensory_testing_returned varchar,
          sensory_testing_notes varchar,
          select_liver_mri_returned varchar,
          liver_mri_notes varchar,
          select_physical_function_returned varchar,
          physical_function_notes varchar,
          select_eeg_returned varchar,
          eeg_notes varchar,
          select_sleep_returned varchar,
          sleep_notes varchar,
          select_cardiology_returned varchar,
          cardiology_notes varchar,
          select_xray_returned varchar,
          xray_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_four_wk_followup_id integer
      );

      CREATE SEQUENCE sleep_four_wk_followup_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_four_wk_followup_history_id_seq OWNED BY sleep_four_wk_followup_history.id;

      CREATE TABLE sleep_four_wk_followups (
          id integer NOT NULL,
          master_id integer,
          select_all_results_returned varchar,
          select_sensory_testing_returned varchar,
          sensory_testing_notes varchar,
          select_liver_mri_returned varchar,
          liver_mri_notes varchar,
          select_physical_function_returned varchar,
          physical_function_notes varchar,
          select_eeg_returned varchar,
          eeg_notes varchar,
          select_sleep_returned varchar,
          sleep_notes varchar,
          select_cardiology_returned varchar,
          cardiology_notes varchar,
          select_xray_returned varchar,
          xray_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_four_wk_followups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_four_wk_followups_id_seq OWNED BY sleep_four_wk_followups.id;

      ALTER TABLE ONLY sleep_four_wk_followups ALTER COLUMN id SET DEFAULT nextval('sleep_four_wk_followups_id_seq'::regclass);
      ALTER TABLE ONLY sleep_four_wk_followup_history ALTER COLUMN id SET DEFAULT nextval('sleep_four_wk_followup_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_four_wk_followup_history
          ADD CONSTRAINT sleep_four_wk_followup_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_four_wk_followups
          ADD CONSTRAINT sleep_four_wk_followups_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_four_wk_followup_history_on_master_id ON sleep_four_wk_followup_history USING btree (master_id);


      CREATE INDEX index_sleep_four_wk_followup_history_on_sleep_four_wk_followup_id ON sleep_four_wk_followup_history USING btree (sleep_four_wk_followup_id);
      CREATE INDEX index_sleep_four_wk_followup_history_on_user_id ON sleep_four_wk_followup_history USING btree (user_id);

      CREATE INDEX index_sleep_four_wk_followups_on_master_id ON sleep_four_wk_followups USING btree (master_id);

      CREATE INDEX index_sleep_four_wk_followups_on_user_id ON sleep_four_wk_followups USING btree (user_id);

      CREATE TRIGGER sleep_four_wk_followup_history_insert AFTER INSERT ON sleep_four_wk_followups FOR EACH ROW EXECUTE PROCEDURE log_sleep_four_wk_followup_update();
      CREATE TRIGGER sleep_four_wk_followup_history_update AFTER UPDATE ON sleep_four_wk_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_four_wk_followup_update();


      ALTER TABLE ONLY sleep_four_wk_followups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_four_wk_followups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_four_wk_followup_history
          ADD CONSTRAINT fk_sleep_four_wk_followup_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_four_wk_followup_history
          ADD CONSTRAINT fk_sleep_four_wk_followup_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_four_wk_followup_history
          ADD CONSTRAINT fk_sleep_four_wk_followup_history_sleep_four_wk_followups FOREIGN KEY (sleep_four_wk_followup_id) REFERENCES sleep_four_wk_followups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
