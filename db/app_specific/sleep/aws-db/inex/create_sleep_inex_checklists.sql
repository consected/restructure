set search_path=sleep,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_inex_checklists fixed_checklist_type reliable_internet_yes_no cbt_yes_no cbt_how_long_ago sleep_times_yes_no work_night_shifts_yes_no number_times_per_week_work_night_shifts narcolepsy_diagnosis_yes_no_dont_know antiseizure_meds_yes_no seizure_in_ten_years_yes_no major_psychiatric_disorder_yes_no isi_total_score sa_diagnosed_yes_no sa_use_treatment_yes_no sa_severity ese_total_score number_hours_sleep audit_c_total_score alcohol_frequency number_days_negative_feeling_d2 number_days_drug_usage_d2 consent_to_pass_info_to_bwh_yes_no select_subject_eligibility

      CREATE FUNCTION log_sleep_inex_checklist_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_inex_checklist_history
                  (
                      master_id,
                      fixed_checklist_type,
                      reliable_internet_yes_no,
                      cbt_yes_no,
                      cbt_how_long_ago,
                      sleep_times_yes_no,
                      work_night_shifts_yes_no,
                      number_times_per_week_work_night_shifts,
                      narcolepsy_diagnosis_yes_no_dont_know,
                      antiseizure_meds_yes_no,
                      seizure_in_ten_years_yes_no,
                      major_psychiatric_disorder_yes_no,
                      isi_total_score,
                      sa_diagnosed_yes_no,
                      sa_use_treatment_yes_no,
                      sa_severity,
                      ese_total_score,
                      number_hours_sleep,
                      audit_c_total_score,
                      alcohol_frequency,
                      number_days_negative_feeling_d2,
                      number_days_drug_usage_d2,
                      consent_to_pass_info_to_bwh_yes_no,
                      select_subject_eligibility,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_inex_checklist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.fixed_checklist_type,
                      NEW.reliable_internet_yes_no,
                      NEW.cbt_yes_no,
                      NEW.cbt_how_long_ago,
                      NEW.sleep_times_yes_no,
                      NEW.work_night_shifts_yes_no,
                      NEW.number_times_per_week_work_night_shifts,
                      NEW.narcolepsy_diagnosis_yes_no_dont_know,
                      NEW.antiseizure_meds_yes_no,
                      NEW.seizure_in_ten_years_yes_no,
                      NEW.major_psychiatric_disorder_yes_no,
                      NEW.isi_total_score,
                      NEW.sa_diagnosed_yes_no,
                      NEW.sa_use_treatment_yes_no,
                      NEW.sa_severity,
                      NEW.ese_total_score,
                      NEW.number_hours_sleep,
                      NEW.audit_c_total_score,
                      NEW.alcohol_frequency,
                      NEW.number_days_negative_feeling_d2,
                      NEW.number_days_drug_usage_d2,
                      NEW.consent_to_pass_info_to_bwh_yes_no,
                      NEW.select_subject_eligibility,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_inex_checklist_history (
          id integer NOT NULL,
          master_id integer,
          fixed_checklist_type varchar,
          reliable_internet_yes_no varchar,
          cbt_yes_no varchar,
          cbt_how_long_ago varchar,
          sleep_times_yes_no varchar,
          work_night_shifts_yes_no varchar,
          number_times_per_week_work_night_shifts integer,
          narcolepsy_diagnosis_yes_no_dont_know varchar,
          antiseizure_meds_yes_no varchar,
          seizure_in_ten_years_yes_no varchar,
          major_psychiatric_disorder_yes_no varchar,
          isi_total_score integer,
          sa_diagnosed_yes_no varchar,
          sa_use_treatment_yes_no varchar,
          sa_severity varchar,
          ese_total_score integer,
          number_hours_sleep integer,
          audit_c_total_score integer,
          alcohol_frequency varchar,
          number_days_negative_feeling_d2 integer,
          number_days_drug_usage_d2 integer,
          consent_to_pass_info_to_bwh_yes_no varchar,
          select_subject_eligibility varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_inex_checklist_id integer
      );

      CREATE SEQUENCE sleep_inex_checklist_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_inex_checklist_history_id_seq OWNED BY sleep_inex_checklist_history.id;

      CREATE TABLE sleep_inex_checklists (
          id integer NOT NULL,
          master_id integer,
          fixed_checklist_type varchar,
          reliable_internet_yes_no varchar,
          cbt_yes_no varchar,
          cbt_how_long_ago varchar,
          sleep_times_yes_no varchar,
          work_night_shifts_yes_no varchar,
          number_times_per_week_work_night_shifts integer,
          narcolepsy_diagnosis_yes_no_dont_know varchar,
          antiseizure_meds_yes_no varchar,
          seizure_in_ten_years_yes_no varchar,
          major_psychiatric_disorder_yes_no varchar,
          isi_total_score integer,
          sa_diagnosed_yes_no varchar,
          sa_use_treatment_yes_no varchar,
          sa_severity varchar,
          ese_total_score integer,
          number_hours_sleep integer,
          audit_c_total_score integer,
          alcohol_frequency varchar,
          number_days_negative_feeling_d2 integer,
          number_days_drug_usage_d2 integer,
          consent_to_pass_info_to_bwh_yes_no varchar,
          select_subject_eligibility varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_inex_checklists_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_inex_checklists_id_seq OWNED BY sleep_inex_checklists.id;

      ALTER TABLE ONLY sleep_inex_checklists ALTER COLUMN id SET DEFAULT nextval('sleep_inex_checklists_id_seq'::regclass);
      ALTER TABLE ONLY sleep_inex_checklist_history ALTER COLUMN id SET DEFAULT nextval('sleep_inex_checklist_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_inex_checklist_history
          ADD CONSTRAINT sleep_inex_checklist_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_inex_checklists
          ADD CONSTRAINT sleep_inex_checklists_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_inex_checklist_history_on_master_id ON sleep_inex_checklist_history USING btree (master_id);


      CREATE INDEX index_sleep_inex_checklist_history_on_sleep_inex_checklist_id ON sleep_inex_checklist_history USING btree (sleep_inex_checklist_id);
      CREATE INDEX index_sleep_inex_checklist_history_on_user_id ON sleep_inex_checklist_history USING btree (user_id);

      CREATE INDEX index_sleep_inex_checklists_on_master_id ON sleep_inex_checklists USING btree (master_id);

      CREATE INDEX index_sleep_inex_checklists_on_user_id ON sleep_inex_checklists USING btree (user_id);

      CREATE TRIGGER sleep_inex_checklist_history_insert AFTER INSERT ON sleep_inex_checklists FOR EACH ROW EXECUTE PROCEDURE log_sleep_inex_checklist_update();
      CREATE TRIGGER sleep_inex_checklist_history_update AFTER UPDATE ON sleep_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_inex_checklist_update();


      ALTER TABLE ONLY sleep_inex_checklists
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_inex_checklists
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_inex_checklist_history
          ADD CONSTRAINT fk_sleep_inex_checklist_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_inex_checklist_history
          ADD CONSTRAINT fk_sleep_inex_checklist_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_inex_checklist_history
          ADD CONSTRAINT fk_sleep_inex_checklist_history_sleep_inex_checklists FOREIGN KEY (sleep_inex_checklist_id) REFERENCES sleep_inex_checklists(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
