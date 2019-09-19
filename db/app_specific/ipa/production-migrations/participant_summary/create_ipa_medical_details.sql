set search_path=ipa_ops, ml_app;


      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_medical_details convulsion_or_seizure_blank_yes_no_dont_know convulsion_or_seizure_details sleep_disorder_blank_yes_no_dont_know sleep_disorder_details sleep_apnea_device_no_yes sleep_apnea_device_details chronic_pain_blank_yes_no chronic_pain_details chronic_pain_meds_blank_yes_no_dont_know chronic_pain_meds_details hypertension_diagnosis_blank_yes_no_dont_know hypertension_medications_blank_yes_no hypertension_diagnosis_details diabetes_diagnosis_blank_yes_no_dont_know diabetes_medications_blank_yes_no diabetes_diagnosis_details hemophilia_blank_yes_no_dont_know hemophilia_details high_cholesterol_diagnosis_blank_yes_no_dont_know high_cholesterol_medications_blank_yes_no high_cholesterol_diagnosis_details caridiac_pacemaker_blank_yes_no_dont_know caridiac_pacemaker_details other_heart_conditions_blank_yes_no_dont_know other_heart_conditions_details memory_problems_blank_yes_no_dont_know memory_problems_details mental_health_conditions_blank_yes_no_dont_know mental_health_conditions_details mental_health_help_blank_yes_no_dont_know mental_health_help_details neurological_problems_blank_yes_no_dont_know neurological_problems_details past_mri_yes_no_dont_know past_mri_details dietary_restrictions_blank_yes_no_dont_know dietary_restrictions_details

      CREATE FUNCTION log_ipa_medical_detail_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_medical_detail_history
                  (
                      master_id,
                      convulsion_or_seizure_blank_yes_no_dont_know,
                      convulsion_or_seizure_details,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_medications_blank_yes_no,
                      hypertension_diagnosis_details,
                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_medications_blank_yes_no,
                      diabetes_diagnosis_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_medications_blank_yes_no,
                      high_cholesterol_diagnosis_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,
                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,
                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,
                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,
                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,
                      past_mri_yes_no_dont_know,
                      past_mri_details,
                      dietary_restrictions_blank_yes_no_dont_know,
                      dietary_restrictions_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_medical_detail_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.convulsion_or_seizure_blank_yes_no_dont_know,
                      NEW.convulsion_or_seizure_details,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_medications_blank_yes_no,
                      NEW.hypertension_diagnosis_details,
                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_medications_blank_yes_no,
                      NEW.diabetes_diagnosis_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_medications_blank_yes_no,
                      NEW.high_cholesterol_diagnosis_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,
                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,
                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,
                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,
                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,
                      NEW.past_mri_yes_no_dont_know,
                      NEW.past_mri_details,
                      NEW.dietary_restrictions_blank_yes_no_dont_know,
                      NEW.dietary_restrictions_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_medical_detail_history (
          id integer NOT NULL,
          master_id integer,
          convulsion_or_seizure_blank_yes_no_dont_know varchar,
          convulsion_or_seizure_details varchar,
          sleep_disorder_blank_yes_no_dont_know varchar,
          sleep_disorder_details varchar,
          sleep_apnea_device_no_yes varchar,
          sleep_apnea_device_details varchar,
          chronic_pain_blank_yes_no varchar,
          chronic_pain_details varchar,
          chronic_pain_meds_blank_yes_no_dont_know varchar,
          chronic_pain_meds_details varchar,
          hypertension_diagnosis_blank_yes_no_dont_know varchar,
          hypertension_medications_blank_yes_no varchar,
          hypertension_diagnosis_details varchar,
          diabetes_diagnosis_blank_yes_no_dont_know varchar,
          diabetes_medications_blank_yes_no varchar,
          diabetes_diagnosis_details varchar,
          hemophilia_blank_yes_no_dont_know varchar,
          hemophilia_details varchar,
          high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
          high_cholesterol_medications_blank_yes_no varchar,
          high_cholesterol_diagnosis_details varchar,
          caridiac_pacemaker_blank_yes_no_dont_know varchar,
          caridiac_pacemaker_details varchar,
          other_heart_conditions_blank_yes_no_dont_know varchar,
          other_heart_conditions_details varchar,
          memory_problems_blank_yes_no_dont_know varchar,
          memory_problems_details varchar,
          mental_health_conditions_blank_yes_no_dont_know varchar,
          mental_health_conditions_details varchar,
          mental_health_help_blank_yes_no_dont_know varchar,
          mental_health_help_details varchar,
          neurological_problems_blank_yes_no_dont_know varchar,
          neurological_problems_details varchar,
          past_mri_yes_no_dont_know varchar,
          past_mri_details varchar,
          dietary_restrictions_blank_yes_no_dont_know varchar,
          dietary_restrictions_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_medical_detail_id integer
      );

      CREATE SEQUENCE ipa_medical_detail_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_medical_detail_history_id_seq OWNED BY ipa_medical_detail_history.id;

      CREATE TABLE ipa_medical_details (
          id integer NOT NULL,
          master_id integer,
          convulsion_or_seizure_blank_yes_no_dont_know varchar,
          convulsion_or_seizure_details varchar,
          sleep_disorder_blank_yes_no_dont_know varchar,
          sleep_disorder_details varchar,
          sleep_apnea_device_no_yes varchar,
          sleep_apnea_device_details varchar,
          chronic_pain_blank_yes_no varchar,
          chronic_pain_details varchar,
          chronic_pain_meds_blank_yes_no_dont_know varchar,
          chronic_pain_meds_details varchar,
          hypertension_diagnosis_blank_yes_no_dont_know varchar,
          hypertension_medications_blank_yes_no varchar,
          hypertension_diagnosis_details varchar,
          diabetes_diagnosis_blank_yes_no_dont_know varchar,
          diabetes_medications_blank_yes_no varchar,
          diabetes_diagnosis_details varchar,
          hemophilia_blank_yes_no_dont_know varchar,
          hemophilia_details varchar,
          high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
          high_cholesterol_medications_blank_yes_no varchar,
          high_cholesterol_diagnosis_details varchar,
          caridiac_pacemaker_blank_yes_no_dont_know varchar,
          caridiac_pacemaker_details varchar,
          other_heart_conditions_blank_yes_no_dont_know varchar,
          other_heart_conditions_details varchar,
          memory_problems_blank_yes_no_dont_know varchar,
          memory_problems_details varchar,
          mental_health_conditions_blank_yes_no_dont_know varchar,
          mental_health_conditions_details varchar,
          mental_health_help_blank_yes_no_dont_know varchar,
          mental_health_help_details varchar,
          neurological_problems_blank_yes_no_dont_know varchar,
          neurological_problems_details varchar,
          past_mri_yes_no_dont_know varchar,
          past_mri_details varchar,
          dietary_restrictions_blank_yes_no_dont_know varchar,
          dietary_restrictions_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_medical_details_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_medical_details_id_seq OWNED BY ipa_medical_details.id;

      ALTER TABLE ONLY ipa_medical_details ALTER COLUMN id SET DEFAULT nextval('ipa_medical_details_id_seq'::regclass);
      ALTER TABLE ONLY ipa_medical_detail_history ALTER COLUMN id SET DEFAULT nextval('ipa_medical_detail_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_medical_detail_history
          ADD CONSTRAINT ipa_medical_detail_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_medical_details
          ADD CONSTRAINT ipa_medical_details_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_medical_detail_history_on_master_id ON ipa_medical_detail_history USING btree (master_id);


      CREATE INDEX index_ipa_medical_detail_history_on_ipa_medical_detail_id ON ipa_medical_detail_history USING btree (ipa_medical_detail_id);
      CREATE INDEX index_ipa_medical_detail_history_on_user_id ON ipa_medical_detail_history USING btree (user_id);

      CREATE INDEX index_ipa_medical_details_on_master_id ON ipa_medical_details USING btree (master_id);

      CREATE INDEX index_ipa_medical_details_on_user_id ON ipa_medical_details USING btree (user_id);

      CREATE TRIGGER ipa_medical_detail_history_insert AFTER INSERT ON ipa_medical_details FOR EACH ROW EXECUTE PROCEDURE log_ipa_medical_detail_update();
      CREATE TRIGGER ipa_medical_detail_history_update AFTER UPDATE ON ipa_medical_details FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_medical_detail_update();


      ALTER TABLE ONLY ipa_medical_details
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_medical_details
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_medical_detail_history
          ADD CONSTRAINT fk_ipa_medical_detail_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_medical_detail_history
          ADD CONSTRAINT fk_ipa_medical_detail_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_medical_detail_history
          ADD CONSTRAINT fk_ipa_medical_detail_history_ipa_medical_details FOREIGN KEY (ipa_medical_detail_id) REFERENCES ipa_medical_details(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
