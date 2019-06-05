
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ${target_name_us}_inex_checklists false fixed_checklist_type ix_consent_blank_yes_no ix_consent_details ix_not_pro_blank_yes_no ix_not_pro_details ix_age_range_blank_yes_no ix_age_range_details ix_weight_ok_blank_yes_no ix_weight_ok_details ix_no_seizure_blank_yes_no ix_no_seizure_details ix_no_device_impl_blank_yes_no ix_no_device_impl_details ix_no_ferromagnetic_impl_blank_yes_no ix_no_ferromagnetic_impl_details ix_diagnosed_sleep_apnea_blank_yes_no ix_diagnosed_sleep_apnea_details ix_diagnosed_heart_stroke_or_meds_blank_yes_no ix_diagnosed_heart_stroke_or_meds_details ix_chronic_pain_and_meds_blank_yes_no ix_chronic_pain_and_meds_details ix_tmoca_score_blank_yes_no ix_tmoca_score_details ix_no_hemophilia_blank_yes_no ix_no_hemophilia_details ix_raynauds_ok_blank_yes_no ix_raynauds_ok_details ix_mi_ok_blank_yes_no ix_mi_ok_details ix_bicycle_ok_blank_yes_no ix_bicycle_ok_details

      CREATE FUNCTION log_${target_name_us}_inex_checklist_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_inex_checklist_history
                  (
                      master_id,
                      fixed_checklist_type,
                      ix_consent_blank_yes_no,
                      ix_consent_details,
                      ix_not_pro_blank_yes_no,
                      ix_not_pro_details,
                      ix_age_range_blank_yes_no,
                      ix_age_range_details,
                      ix_weight_ok_blank_yes_no,
                      ix_weight_ok_details,
                      ix_no_seizure_blank_yes_no,
                      ix_no_seizure_details,
                      ix_no_device_impl_blank_yes_no,
                      ix_no_device_impl_details,
                      ix_no_ferromagnetic_impl_blank_yes_no,
                      ix_no_ferromagnetic_impl_details,
                      ix_diagnosed_sleep_apnea_blank_yes_no,
                      ix_diagnosed_sleep_apnea_details,
                      ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      ix_diagnosed_heart_stroke_or_meds_details,
                      ix_chronic_pain_and_meds_blank_yes_no,
                      ix_chronic_pain_and_meds_details,
                      ix_tmoca_score_blank_yes_no,
                      ix_tmoca_score_details,
                      ix_no_hemophilia_blank_yes_no,
                      ix_no_hemophilia_details,
                      ix_raynauds_ok_blank_yes_no,
                      ix_raynauds_ok_details,
                      ix_mi_ok_blank_yes_no,
                      ix_mi_ok_details,
                      ix_bicycle_ok_blank_yes_no,
                      ix_bicycle_ok_details,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_inex_checklist_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.fixed_checklist_type,
                      NEW.ix_consent_blank_yes_no,
                      NEW.ix_consent_details,
                      NEW.ix_not_pro_blank_yes_no,
                      NEW.ix_not_pro_details,
                      NEW.ix_age_range_blank_yes_no,
                      NEW.ix_age_range_details,
                      NEW.ix_weight_ok_blank_yes_no,
                      NEW.ix_weight_ok_details,
                      NEW.ix_no_seizure_blank_yes_no,
                      NEW.ix_no_seizure_details,
                      NEW.ix_no_device_impl_blank_yes_no,
                      NEW.ix_no_device_impl_details,
                      NEW.ix_no_ferromagnetic_impl_blank_yes_no,
                      NEW.ix_no_ferromagnetic_impl_details,
                      NEW.ix_diagnosed_sleep_apnea_blank_yes_no,
                      NEW.ix_diagnosed_sleep_apnea_details,
                      NEW.ix_diagnosed_heart_stroke_or_meds_blank_yes_no,
                      NEW.ix_diagnosed_heart_stroke_or_meds_details,
                      NEW.ix_chronic_pain_and_meds_blank_yes_no,
                      NEW.ix_chronic_pain_and_meds_details,
                      NEW.ix_tmoca_score_blank_yes_no,
                      NEW.ix_tmoca_score_details,
                      NEW.ix_no_hemophilia_blank_yes_no,
                      NEW.ix_no_hemophilia_details,
                      NEW.ix_raynauds_ok_blank_yes_no,
                      NEW.ix_raynauds_ok_details,
                      NEW.ix_mi_ok_blank_yes_no,
                      NEW.ix_mi_ok_details,
                      NEW.ix_bicycle_ok_blank_yes_no,
                      NEW.ix_bicycle_ok_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_inex_checklist_history (
          id integer NOT NULL,
          master_id integer,
          fixed_checklist_type varchar,
          ix_consent_blank_yes_no varchar,
          ix_consent_details varchar,
          ix_not_pro_blank_yes_no varchar,
          ix_not_pro_details varchar,
          ix_age_range_blank_yes_no varchar,
          ix_age_range_details varchar,
          ix_weight_ok_blank_yes_no varchar,
          ix_weight_ok_details varchar,
          ix_no_seizure_blank_yes_no varchar,
          ix_no_seizure_details varchar,
          ix_no_device_impl_blank_yes_no varchar,
          ix_no_device_impl_details varchar,
          ix_no_ferromagnetic_impl_blank_yes_no varchar,
          ix_no_ferromagnetic_impl_details varchar,
          ix_diagnosed_sleep_apnea_blank_yes_no varchar,
          ix_diagnosed_sleep_apnea_details varchar,
          ix_diagnosed_heart_stroke_or_meds_blank_yes_no varchar,
          ix_diagnosed_heart_stroke_or_meds_details varchar,
          ix_chronic_pain_and_meds_blank_yes_no varchar,
          ix_chronic_pain_and_meds_details varchar,
          ix_tmoca_score_blank_yes_no varchar,
          ix_tmoca_score_details varchar,
          ix_no_hemophilia_blank_yes_no varchar,
          ix_no_hemophilia_details varchar,
          ix_raynauds_ok_blank_yes_no varchar,
          ix_raynauds_ok_details varchar,
          ix_mi_ok_blank_yes_no varchar,
          ix_mi_ok_details varchar,
          ix_bicycle_ok_blank_yes_no varchar,
          ix_bicycle_ok_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_inex_checklist_id integer
      );

      CREATE SEQUENCE ${target_name_us}_inex_checklist_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_inex_checklist_history_id_seq OWNED BY ${target_name_us}_inex_checklist_history.id;

      CREATE TABLE ${target_name_us}_inex_checklists (
          id integer NOT NULL,
          master_id integer,
          fixed_checklist_type varchar,
          ix_consent_blank_yes_no varchar,
          ix_consent_details varchar,
          ix_not_pro_blank_yes_no varchar,
          ix_not_pro_details varchar,
          ix_age_range_blank_yes_no varchar,
          ix_age_range_details varchar,
          ix_weight_ok_blank_yes_no varchar,
          ix_weight_ok_details varchar,
          ix_no_seizure_blank_yes_no varchar,
          ix_no_seizure_details varchar,
          ix_no_device_impl_blank_yes_no varchar,
          ix_no_device_impl_details varchar,
          ix_no_ferromagnetic_impl_blank_yes_no varchar,
          ix_no_ferromagnetic_impl_details varchar,
          ix_diagnosed_sleep_apnea_blank_yes_no varchar,
          ix_diagnosed_sleep_apnea_details varchar,
          ix_diagnosed_heart_stroke_or_meds_blank_yes_no varchar,
          ix_diagnosed_heart_stroke_or_meds_details varchar,
          ix_chronic_pain_and_meds_blank_yes_no varchar,
          ix_chronic_pain_and_meds_details varchar,
          ix_tmoca_score_blank_yes_no varchar,
          ix_tmoca_score_details varchar,
          ix_no_hemophilia_blank_yes_no varchar,
          ix_no_hemophilia_details varchar,
          ix_raynauds_ok_blank_yes_no varchar,
          ix_raynauds_ok_details varchar,
          ix_mi_ok_blank_yes_no varchar,
          ix_mi_ok_details varchar,
          ix_bicycle_ok_blank_yes_no varchar,
          ix_bicycle_ok_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_inex_checklists_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_inex_checklists_id_seq OWNED BY ${target_name_us}_inex_checklists.id;

      ALTER TABLE ONLY ${target_name_us}_inex_checklists ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_inex_checklists_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_inex_checklist_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_inex_checklist_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_inex_checklist_history
          ADD CONSTRAINT ${target_name_us}_inex_checklist_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_inex_checklists
          ADD CONSTRAINT ${target_name_us}_inex_checklists_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_inex_checklist_history_on_master_id ON ${target_name_us}_inex_checklist_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_inex_checklist_history_on_${target_name_us}_inex_checklist_id ON ${target_name_us}_inex_checklist_history USING btree (${target_name_us}_inex_checklist_id);
      CREATE INDEX index_${target_name_us}_inex_checklist_history_on_user_id ON ${target_name_us}_inex_checklist_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_inex_checklists_on_master_id ON ${target_name_us}_inex_checklists USING btree (master_id);

      CREATE INDEX index_${target_name_us}_inex_checklists_on_user_id ON ${target_name_us}_inex_checklists USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_inex_checklist_history_insert AFTER INSERT ON ${target_name_us}_inex_checklists FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_inex_checklist_update();
      CREATE TRIGGER ${target_name_us}_inex_checklist_history_update AFTER UPDATE ON ${target_name_us}_inex_checklists FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_inex_checklist_update();


      ALTER TABLE ONLY ${target_name_us}_inex_checklists
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_inex_checklists
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_inex_checklist_history
          ADD CONSTRAINT fk_${target_name_us}_inex_checklist_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_inex_checklist_history
          ADD CONSTRAINT fk_${target_name_us}_inex_checklist_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_inex_checklist_history
          ADD CONSTRAINT fk_${target_name_us}_inex_checklist_history_${target_name_us}_inex_checklists FOREIGN KEY (${target_name_us}_inex_checklist_id) REFERENCES ${target_name_us}_inex_checklists(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
