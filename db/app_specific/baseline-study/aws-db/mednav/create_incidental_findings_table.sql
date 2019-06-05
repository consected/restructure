set search_path=${target_name_us}_ops,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ${target_name_us}_incidental_findings anthropometrics_check anthropometrics_date anthropometrics_notes lab_results_check lab_results_date lab_results_notes dexa_check dexa_date dexa_notes brain_mri_check brain_mri_date brain_mri_notes neuro_psych_check neuro_psych_date neuro_psych_notes sensory_testing_check sensory_testing_date sensory_testing_notes liver_mri_check liver_mri_date liver_mri_notes physical_function_check physical_function_date physical_function_notes eeg_check eeg_date eeg_notes sleep_check sleep_date sleep_notes cardiac_check cardiac_date cardiac_notes xray_check xray_date xray_notes other_notes

      CREATE FUNCTION log_${target_name_us}_incidental_finding_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_incidental_finding_history
                  (
                      master_id,
                      anthropometrics_check,
                      anthropometrics_date,
                      anthropometrics_notes,
                      lab_results_check,
                      lab_results_date,
                      lab_results_notes,
                      dexa_check,
                      dexa_date,
                      dexa_notes,
                      brain_mri_check,
                      brain_mri_date,
                      brain_mri_notes,
                      neuro_psych_check,
                      neuro_psych_date,
                      neuro_psych_notes,
                      sensory_testing_check,
                      sensory_testing_date,
                      sensory_testing_notes,
                      liver_mri_check,
                      liver_mri_date,
                      liver_mri_notes,
                      physical_function_check,
                      physical_function_date,
                      physical_function_notes,
                      eeg_check,
                      eeg_date,
                      eeg_notes,
                      sleep_check,
                      sleep_date,
                      sleep_notes,
                      cardiac_check,
                      cardiac_date,
                      cardiac_notes,
                      xray_check,
                      xray_date,
                      xray_notes,
                      other_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_incidental_finding_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.anthropometrics_check,
                      NEW.anthropometrics_date,
                      NEW.anthropometrics_notes,
                      NEW.lab_results_check,
                      NEW.lab_results_date,
                      NEW.lab_results_notes,
                      NEW.dexa_check,
                      NEW.dexa_date,
                      NEW.dexa_notes,
                      NEW.brain_mri_check,
                      NEW.brain_mri_date,
                      NEW.brain_mri_notes,
                      NEW.neuro_psych_check,
                      NEW.neuro_psych_date,
                      NEW.neuro_psych_notes,
                      NEW.sensory_testing_check,
                      NEW.sensory_testing_date,
                      NEW.sensory_testing_notes,
                      NEW.liver_mri_check,
                      NEW.liver_mri_date,
                      NEW.liver_mri_notes,
                      NEW.physical_function_check,
                      NEW.physical_function_date,
                      NEW.physical_function_notes,
                      NEW.eeg_check,
                      NEW.eeg_date,
                      NEW.eeg_notes,
                      NEW.sleep_check,
                      NEW.sleep_date,
                      NEW.sleep_notes,
                      NEW.cardiac_check,
                      NEW.cardiac_date,
                      NEW.cardiac_notes,
                      NEW.xray_check,
                      NEW.xray_date,
                      NEW.xray_notes,
                      NEW.other_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_incidental_finding_history (
          id integer NOT NULL,
          master_id integer,
          anthropometrics_check boolean,
          anthropometrics_date date,
          anthropometrics_notes varchar,
          lab_results_check boolean,
          lab_results_date date,
          lab_results_notes varchar,
          dexa_check boolean,
          dexa_date date,
          dexa_notes varchar,
          brain_mri_check boolean,
          brain_mri_date date,
          brain_mri_notes varchar,
          neuro_psych_check boolean,
          neuro_psych_date date,
          neuro_psych_notes varchar,
          sensory_testing_check boolean,
          sensory_testing_date date,
          sensory_testing_notes varchar,
          liver_mri_check boolean,
          liver_mri_date date,
          liver_mri_notes varchar,
          physical_function_check boolean,
          physical_function_date date,
          physical_function_notes varchar,
          eeg_check boolean,
          eeg_date date,
          eeg_notes varchar,
          sleep_check boolean,
          sleep_date date,
          sleep_notes varchar,
          cardiac_check boolean,
          cardiac_date date,
          cardiac_notes varchar,
          xray_check boolean,
          xray_date date,
          xray_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_incidental_finding_id integer
      );

      CREATE SEQUENCE ${target_name_us}_incidental_finding_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_incidental_finding_history_id_seq OWNED BY ${target_name_us}_incidental_finding_history.id;

      CREATE TABLE ${target_name_us}_incidental_findings (
          id integer NOT NULL,
          master_id integer,
          anthropometrics_check boolean,
          anthropometrics_date date,
          anthropometrics_notes varchar,
          lab_results_check boolean,
          lab_results_date date,
          lab_results_notes varchar,
          dexa_check boolean,
          dexa_date date,
          dexa_notes varchar,
          brain_mri_check boolean,
          brain_mri_date date,
          brain_mri_notes varchar,
          neuro_psych_check boolean,
          neuro_psych_date date,
          neuro_psych_notes varchar,
          sensory_testing_check boolean,
          sensory_testing_date date,
          sensory_testing_notes varchar,
          liver_mri_check boolean,
          liver_mri_date date,
          liver_mri_notes varchar,
          physical_function_check boolean,
          physical_function_date date,
          physical_function_notes varchar,
          eeg_check boolean,
          eeg_date date,
          eeg_notes varchar,
          sleep_check boolean,
          sleep_date date,
          sleep_notes varchar,
          cardiac_check boolean,
          cardiac_date date,
          cardiac_notes varchar,
          xray_check boolean,
          xray_date date,
          xray_notes varchar,
          other_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_incidental_findings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_incidental_findings_id_seq OWNED BY ${target_name_us}_incidental_findings.id;

      ALTER TABLE ONLY ${target_name_us}_incidental_findings ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_incidental_findings_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_incidental_finding_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_incidental_finding_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_incidental_finding_history
          ADD CONSTRAINT ${target_name_us}_incidental_finding_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_incidental_findings
          ADD CONSTRAINT ${target_name_us}_incidental_findings_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_incidental_finding_history_on_master_id ON ${target_name_us}_incidental_finding_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_incidental_finding_history_on_${target_name_us}_incidental_finding_id ON ${target_name_us}_incidental_finding_history USING btree (${target_name_us}_incidental_finding_id);
      CREATE INDEX index_${target_name_us}_incidental_finding_history_on_user_id ON ${target_name_us}_incidental_finding_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_incidental_findings_on_master_id ON ${target_name_us}_incidental_findings USING btree (master_id);

      CREATE INDEX index_${target_name_us}_incidental_findings_on_user_id ON ${target_name_us}_incidental_findings USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_incidental_finding_history_insert AFTER INSERT ON ${target_name_us}_incidental_findings FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_incidental_finding_update();
      CREATE TRIGGER ${target_name_us}_incidental_finding_history_update AFTER UPDATE ON ${target_name_us}_incidental_findings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_incidental_finding_update();


      ALTER TABLE ONLY ${target_name_us}_incidental_findings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_incidental_findings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_incidental_finding_history
          ADD CONSTRAINT fk_${target_name_us}_incidental_finding_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_incidental_finding_history
          ADD CONSTRAINT fk_${target_name_us}_incidental_finding_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_incidental_finding_history
          ADD CONSTRAINT fk_${target_name_us}_incidental_finding_history_${target_name_us}_incidental_findings FOREIGN KEY (${target_name_us}_incidental_finding_id) REFERENCES ${target_name_us}_incidental_findings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
