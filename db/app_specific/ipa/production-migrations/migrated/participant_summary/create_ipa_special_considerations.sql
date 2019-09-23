set search_path=ipa_ops, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_special_considerations travel_with_wife_yes_no travel_with_wife_details mmse_yes_no tmoca_score bringing_cpap_yes_no tms_exempt_yes_no taking_med_for_mri_pet_yes_no

      CREATE or REPLACE FUNCTION log_ipa_special_consideration_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_special_consideration_history
                  (
                      master_id,
                      travel_with_wife_yes_no,
                      travel_with_wife_details,
                      mmse_yes_no,
                      tmoca_score,
                      mmse_details,
                      bringing_cpap_yes_no,
                      tms_exempt_yes_no,
                      taking_med_for_mri_pet_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_special_consideration_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.travel_with_wife_yes_no,
                      NEW.travel_with_wife_details,
                      NEW.mmse_yes_no,
                      NEW.tmoca_score,
                      NEW.mmse_details,
                      NEW.bringing_cpap_yes_no,
                      NEW.tms_exempt_yes_no,
                      NEW.taking_med_for_mri_pet_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_special_consideration_history (
          id integer NOT NULL,
          master_id integer,
          travel_with_wife_yes_no varchar,
          travel_with_wife_details varchar,
          mmse_yes_no varchar,
          tmoca_score varchar,
          mmse_details varchar,
          bringing_cpap_yes_no varchar,
          tms_exempt_yes_no varchar,
          taking_med_for_mri_pet_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_special_consideration_id integer
      );

      CREATE SEQUENCE ipa_special_consideration_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_special_consideration_history_id_seq OWNED BY ipa_special_consideration_history.id;

      CREATE TABLE ipa_special_considerations (
          id integer NOT NULL,
          master_id integer,
          travel_with_wife_yes_no varchar,
          travel_with_wife_details varchar,
          mmse_yes_no varchar,
          tmoca_score varchar,
          mmse_details varchar,
          bringing_cpap_yes_no varchar,
          tms_exempt_yes_no varchar,
          taking_med_for_mri_pet_yes_no varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_special_considerations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_special_considerations_id_seq OWNED BY ipa_special_considerations.id;

      ALTER TABLE ONLY ipa_special_considerations ALTER COLUMN id SET DEFAULT nextval('ipa_special_considerations_id_seq'::regclass);
      ALTER TABLE ONLY ipa_special_consideration_history ALTER COLUMN id SET DEFAULT nextval('ipa_special_consideration_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_special_consideration_history
          ADD CONSTRAINT ipa_special_consideration_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_special_considerations
          ADD CONSTRAINT ipa_special_considerations_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_special_consideration_history_on_master_id ON ipa_special_consideration_history USING btree (master_id);


      CREATE INDEX index_ipa_special_consideration_history_on_ipa_special_consideration_id ON ipa_special_consideration_history USING btree (ipa_special_consideration_id);
      CREATE INDEX index_ipa_special_consideration_history_on_user_id ON ipa_special_consideration_history USING btree (user_id);

      CREATE INDEX index_ipa_special_considerations_on_master_id ON ipa_special_considerations USING btree (master_id);

      CREATE INDEX index_ipa_special_considerations_on_user_id ON ipa_special_considerations USING btree (user_id);

      CREATE TRIGGER ipa_special_consideration_history_insert AFTER INSERT ON ipa_special_considerations FOR EACH ROW EXECUTE PROCEDURE log_ipa_special_consideration_update();
      CREATE TRIGGER ipa_special_consideration_history_update AFTER UPDATE ON ipa_special_considerations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_special_consideration_update();


      ALTER TABLE ONLY ipa_special_considerations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_special_considerations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_special_consideration_history
          ADD CONSTRAINT fk_ipa_special_consideration_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_special_consideration_history
          ADD CONSTRAINT fk_ipa_special_consideration_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_special_consideration_history
          ADD CONSTRAINT fk_ipa_special_consideration_history_ipa_special_considerations FOREIGN KEY (ipa_special_consideration_id) REFERENCES ipa_special_considerations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
