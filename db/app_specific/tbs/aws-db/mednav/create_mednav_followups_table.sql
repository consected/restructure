set search_path=tbs,ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create tbs_mednav_followups anthropometrics_check anthropometrics_notes lab_results_check lab_results_notes dexa_check dexa_notes brain_mri_check brain_mri_notes neuro_psych_check neuro_psych_notes sensory_testing_check sensory_testing_notes liver_mri_check liver_mri_notes physical_function_check physical_function_notes eeg_check eeg_notes sleep_check sleep_notes cardiac_check cardiac_notes xray_check xray_notes participant_call_yes_no participant_call_date participant_call_notes provider_call_yes_no provider_call_date provider_call_notes reports_sent_yes_no reports_sent_notes report_sent_date report_delivery_date assisted_finding_provider_yes_no assistance_notes other_notes

      CREATE or REPLACE FUNCTION log_tbs_mednav_followup_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO tbs_mednav_followup_history
                  (
                      master_id,
                      anthropometrics_check,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_notes,
                      dexa_check,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_notes,
                      eeg_check,
                      eeg_notes,
                      sleep_check,
                      sleep_notes,
                      cardiac_check,
                      cardiac_notes,
                      xray_check,
                      xray_notes,
                      assisted_finding_provider_yes_no,
                      assistance_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      tbs_mednav_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_notes,
                      NEW.xray_check,
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

      CREATE TABLE tbs_mednav_followup_history (
          id integer NOT NULL,
          master_id integer,
          anthropometrics_check boolean,
          anthropometrics_notes varchar,
          lab_results_check boolean,
          lab_results_notes varchar,
          dexa_check boolean,
          dexa_notes varchar,
          brain_mri_check boolean,
          brain_mri_notes varchar,
          neuro_psych_check boolean,
          neuro_psych_notes varchar,
          sensory_testing_check boolean,
          sensory_testing_notes varchar,
          liver_mri_check boolean,
          liver_mri_notes varchar,
          physical_function_check boolean,
          physical_function_notes varchar,
          eeg_check boolean,
          eeg_notes varchar,
          sleep_check boolean,
          sleep_notes varchar,
          cardiac_check boolean,
          cardiac_notes varchar,
          xray_check boolean,
          xray_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          tbs_mednav_followup_id integer
      );

      CREATE SEQUENCE tbs_mednav_followup_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_mednav_followup_history_id_seq OWNED BY tbs_mednav_followup_history.id;

      CREATE TABLE tbs_mednav_followups (
          id integer NOT NULL,
          master_id integer,
          anthropometrics_check boolean,
          anthropometrics_notes varchar,
          lab_results_check boolean,
          lab_results_notes varchar,
          dexa_check boolean,
          dexa_notes varchar,
          brain_mri_check boolean,
          brain_mri_notes varchar,
          neuro_psych_check boolean,
          neuro_psych_notes varchar,
          sensory_testing_check boolean,
          sensory_testing_notes varchar,
          liver_mri_check boolean,
          liver_mri_notes varchar,
          physical_function_check boolean,
          physical_function_notes varchar,
          eeg_check boolean,
          eeg_notes varchar,
          sleep_check boolean,
          sleep_notes varchar,
          cardiac_check boolean,
          cardiac_notes varchar,
          xray_check boolean,
          xray_notes varchar,
          assisted_finding_provider_yes_no varchar,
          assistance_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE tbs_mednav_followups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_mednav_followups_id_seq OWNED BY tbs_mednav_followups.id;

      ALTER TABLE ONLY tbs_mednav_followups ALTER COLUMN id SET DEFAULT nextval('tbs_mednav_followups_id_seq'::regclass);
      ALTER TABLE ONLY tbs_mednav_followup_history ALTER COLUMN id SET DEFAULT nextval('tbs_mednav_followup_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_mednav_followup_history
          ADD CONSTRAINT tbs_mednav_followup_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_mednav_followups
          ADD CONSTRAINT tbs_mednav_followups_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_mednav_followup_history_on_master_id ON tbs_mednav_followup_history USING btree (master_id);


      CREATE INDEX index_tbs_mednav_followup_history_on_tbs_mednav_followup_id ON tbs_mednav_followup_history USING btree (tbs_mednav_followup_id);
      CREATE INDEX index_tbs_mednav_followup_history_on_user_id ON tbs_mednav_followup_history USING btree (user_id);

      CREATE INDEX index_tbs_mednav_followups_on_master_id ON tbs_mednav_followups USING btree (master_id);

      CREATE INDEX index_tbs_mednav_followups_on_user_id ON tbs_mednav_followups USING btree (user_id);

      CREATE TRIGGER tbs_mednav_followup_history_insert AFTER INSERT ON tbs_mednav_followups FOR EACH ROW EXECUTE PROCEDURE log_tbs_mednav_followup_update();
      CREATE TRIGGER tbs_mednav_followup_history_update AFTER UPDATE ON tbs_mednav_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_mednav_followup_update();


      ALTER TABLE ONLY tbs_mednav_followups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_mednav_followups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_mednav_followup_history
          ADD CONSTRAINT fk_tbs_mednav_followup_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_mednav_followup_history
          ADD CONSTRAINT fk_tbs_mednav_followup_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_mednav_followup_history
          ADD CONSTRAINT fk_tbs_mednav_followup_history_tbs_mednav_followups FOREIGN KEY (tbs_mednav_followup_id) REFERENCES tbs_mednav_followups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
