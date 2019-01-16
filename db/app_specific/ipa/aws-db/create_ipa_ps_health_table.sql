
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_healths false physical_limitations_blank_yes_no physical_limitations_details sit_back_blank_yes_no sit_back_details cycle_blank_yes_no cycle_details chronic_pain_blank_yes_no chronic_pain_details chronic_pain_meds_blank_yes_no_dont_know chronic_pain_meds_details hemophilia_blank_yes_no_dont_know hemophilia_details raynauds_syndrome_blank_yes_no_dont_know raynauds_syndrome_severity_selection raynauds_syndrome_details other_conditions_blank_yes_no_dont_know other_conditions_details hypertension_diagnosis_blank_yes_no_dont_know hypertension_diagnosis_details other_heart_conditions_blank_yes_no_dont_know other_heart_conditions_details memory_problems_blank_yes_no_dont_know memory_problems_details mental_health_conditions_blank_yes_no_dont_know mental_health_conditions_details neurological_problems_blank_yes_no_dont_know neurological_problems_details

      CREATE FUNCTION log_ipa_ps_health_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_health_history
                  (
                      master_id,
                      physical_limitations_blank_yes_no,
                      physical_limitations_details,
                      sit_back_blank_yes_no,
                      sit_back_details,
                      cycle_blank_yes_no,
                      cycle_details,
                      chronic_pain_blank_yes_no,
                      chronic_pain_details,
                      chronic_pain_meds_blank_yes_no_dont_know,
                      chronic_pain_meds_details,
                      hemophilia_blank_yes_no_dont_know,
                      hemophilia_details,
                      raynauds_syndrome_blank_yes_no_dont_know,
                      raynauds_syndrome_severity_selection,
                      raynauds_syndrome_details,

                      hypertension_diagnosis_blank_yes_no_dont_know,
                      hypertension_medications_blank_yes_no,
                      hypertension_diagnosis_details,

                      diabetes_diagnosis_blank_yes_no_dont_know,
                      diabetes_medications_blank_yes_no,
                      diabetes_diagnosis_details,

                      high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      high_cholesterol_medications_blank_yes_no,
                      high_cholesterol_diagnosis_details,

                      other_heart_conditions_blank_yes_no_dont_know,
                      other_heart_conditions_details,

                      heart_surgeries_blank_yes_no_dont_know,
                      heart_surgeries_details,
                      caridiac_pacemaker_blank_yes_no_dont_know,
                      caridiac_pacemaker_details,

                      memory_problems_blank_yes_no_dont_know,
                      memory_problems_details,
                      mental_health_conditions_blank_yes_no_dont_know,
                      mental_health_conditions_details,

                      mental_health_help_blank_yes_no_dont_know,
                      mental_health_help_details,

                      neurological_problems_blank_yes_no_dont_know,
                      neurological_problems_details,

                      neurological_surgeries_blank_yes_no_dont_know,
                      neurological_surgeries_details,

                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_health_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.physical_limitations_blank_yes_no,
                      NEW.physical_limitations_details,
                      NEW.sit_back_blank_yes_no,
                      NEW.sit_back_details,
                      NEW.cycle_blank_yes_no,
                      NEW.cycle_details,
                      NEW.chronic_pain_blank_yes_no,
                      NEW.chronic_pain_details,
                      NEW.chronic_pain_meds_blank_yes_no_dont_know,
                      NEW.chronic_pain_meds_details,
                      NEW.hemophilia_blank_yes_no_dont_know,
                      NEW.hemophilia_details,
                      NEW.raynauds_syndrome_blank_yes_no_dont_know,
                      NEW.raynauds_syndrome_severity_selection,
                      NEW.raynauds_syndrome_details,

                      NEW.hypertension_diagnosis_blank_yes_no_dont_know,
                      NEW.hypertension_medications_blank_yes_no,
                      NEW.hypertension_diagnosis_details,

                      NEW.diabetes_diagnosis_blank_yes_no_dont_know,
                      NEW.diabetes_medications_blank_yes_no,
                      NEW.diabetes_diagnosis_details,

                      NEW.high_cholesterol_diagnosis_blank_yes_no_dont_know,
                      NEW.high_cholesterol_medications_blank_yes_no,
                      NEW.high_cholesterol_diagnosis_details,

                      NEW.other_heart_conditions_blank_yes_no_dont_know,
                      NEW.other_heart_conditions_details,

                      NEW.heart_surgeries_blank_yes_no_dont_know,
                      NEW.heart_surgeries_details,
                      NEW.caridiac_pacemaker_blank_yes_no_dont_know,
                      NEW.caridiac_pacemaker_details,

                      NEW.memory_problems_blank_yes_no_dont_know,
                      NEW.memory_problems_details,
                      NEW.mental_health_conditions_blank_yes_no_dont_know,
                      NEW.mental_health_conditions_details,

                      NEW.mental_health_help_blank_yes_no_dont_know,
                      NEW.mental_health_help_details,

                      NEW.neurological_problems_blank_yes_no_dont_know,
                      NEW.neurological_problems_details,

                      NEW.neurological_surgeries_blank_yes_no_dont_know,
                      NEW.neurological_surgeries_details,

                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_health_history (
          id integer NOT NULL,
          master_id integer,
          physical_limitations_blank_yes_no varchar,
          physical_limitations_details varchar,
          sit_back_blank_yes_no varchar,
          sit_back_details varchar,
          cycle_blank_yes_no varchar,
          cycle_details varchar,
          chronic_pain_blank_yes_no varchar,
          chronic_pain_details varchar,
          chronic_pain_meds_blank_yes_no_dont_know varchar,
          chronic_pain_meds_details varchar,
          hemophilia_blank_yes_no_dont_know varchar,
          hemophilia_details varchar,
          raynauds_syndrome_blank_yes_no_dont_know varchar,
          raynauds_syndrome_severity_selection varchar,
          raynauds_syndrome_details varchar,
          -- other_conditions_blank_yes_no_dont_know varchar,
          -- other_conditions_details varchar,
          hypertension_diagnosis_blank_yes_no_dont_know varchar,
          hypertension_medications_blank_yes_no varchar,
          hypertension_diagnosis_details varchar,

          diabetes_diagnosis_blank_yes_no_dont_know varchar,
          diabetes_medications_blank_yes_no varchar,
          diabetes_diagnosis_details varchar,

          high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
          high_cholesterol_medications_blank_yes_no varchar,
          high_cholesterol_diagnosis_details varchar,

          other_heart_conditions_blank_yes_no_dont_know varchar,
          other_heart_conditions_details varchar,

          heart_surgeries_blank_yes_no_dont_know varchar,
          heart_surgeries_details varchar,
          caridiac_pacemaker_blank_yes_no_dont_know varchar,
          caridiac_pacemaker_details varchar,

          memory_problems_blank_yes_no_dont_know varchar,
          memory_problems_details varchar,
          mental_health_conditions_blank_yes_no_dont_know varchar,
          mental_health_conditions_details varchar,

          mental_health_help_blank_yes_no_dont_know varchar,
          mental_health_help_details varchar,

          neurological_problems_blank_yes_no_dont_know varchar,
          neurological_problems_details varchar,

          neurological_surgeries_blank_yes_no_dont_know varchar,
          neurological_surgeries_details varchar,

          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_health_id integer
      );

      CREATE SEQUENCE ipa_ps_health_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_health_history_id_seq OWNED BY ipa_ps_health_history.id;

      CREATE TABLE ipa_ps_healths (
          id integer NOT NULL,
          master_id integer,
          physical_limitations_blank_yes_no varchar,
          physical_limitations_details varchar,
          sit_back_blank_yes_no varchar,
          sit_back_details varchar,
          cycle_blank_yes_no varchar,
          cycle_details varchar,
          chronic_pain_blank_yes_no varchar,
          chronic_pain_details varchar,
          chronic_pain_meds_blank_yes_no_dont_know varchar,
          chronic_pain_meds_details varchar,
          hemophilia_blank_yes_no_dont_know varchar,
          hemophilia_details varchar,
          raynauds_syndrome_blank_yes_no_dont_know varchar,
          raynauds_syndrome_severity_selection varchar,
          raynauds_syndrome_details varchar,
          -- other_conditions_blank_yes_no_dont_know varchar,
          -- other_conditions_details varchar,
          hypertension_diagnosis_blank_yes_no_dont_know varchar,
          hypertension_medications_blank_yes_no varchar,
          hypertension_diagnosis_details varchar,

          diabetes_diagnosis_blank_yes_no_dont_know varchar,
          diabetes_medications_blank_yes_no varchar,
          diabetes_diagnosis_details varchar,

          high_cholesterol_diagnosis_blank_yes_no_dont_know varchar,
          high_cholesterol_medications_blank_yes_no varchar,
          high_cholesterol_diagnosis_details varchar,

          other_heart_conditions_blank_yes_no_dont_know varchar,
          other_heart_conditions_details varchar,

          heart_surgeries_blank_yes_no_dont_know varchar,
          heart_surgeries_details varchar,
          caridiac_pacemaker_blank_yes_no_dont_know varchar,
          caridiac_pacemaker_details varchar,

          memory_problems_blank_yes_no_dont_know varchar,
          memory_problems_details varchar,
          mental_health_conditions_blank_yes_no_dont_know varchar,
          mental_health_conditions_details varchar,

          mental_health_help_blank_yes_no_dont_know varchar,
          mental_health_help_details varchar,

          neurological_problems_blank_yes_no_dont_know varchar,
          neurological_problems_details varchar,

          neurological_surgeries_blank_yes_no_dont_know varchar,
          neurological_surgeries_details varchar,

          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_healths_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_healths_id_seq OWNED BY ipa_ps_healths.id;

      ALTER TABLE ONLY ipa_ps_healths ALTER COLUMN id SET DEFAULT nextval('ipa_ps_healths_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_health_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_health_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_health_history
          ADD CONSTRAINT ipa_ps_health_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_healths
          ADD CONSTRAINT ipa_ps_healths_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_health_history_on_master_id ON ipa_ps_health_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_health_history_on_ipa_ps_health_id ON ipa_ps_health_history USING btree (ipa_ps_health_id);
      CREATE INDEX index_ipa_ps_health_history_on_user_id ON ipa_ps_health_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_healths_on_master_id ON ipa_ps_healths USING btree (master_id);

      CREATE INDEX index_ipa_ps_healths_on_user_id ON ipa_ps_healths USING btree (user_id);

      CREATE TRIGGER ipa_ps_health_history_insert AFTER INSERT ON ipa_ps_healths FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_health_update();
      CREATE TRIGGER ipa_ps_health_history_update AFTER UPDATE ON ipa_ps_healths FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_health_update();


      ALTER TABLE ONLY ipa_ps_healths
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_healths
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_health_history
          ADD CONSTRAINT fk_ipa_ps_health_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_health_history
          ADD CONSTRAINT fk_ipa_ps_health_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_health_history
          ADD CONSTRAINT fk_ipa_ps_health_history_ipa_ps_healths FOREIGN KEY (ipa_ps_health_id) REFERENCES ipa_ps_healths(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
