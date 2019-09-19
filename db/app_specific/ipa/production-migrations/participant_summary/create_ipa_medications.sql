set search_path=ipa_ops, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_medications current_meds_blank_yes_no_dont_know current_meds_details

      CREATE FUNCTION log_ipa_medication_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_medication_history
                  (
                      master_id,
                      current_meds_blank_yes_no_dont_know,
                      current_meds_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_medication_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.current_meds_blank_yes_no_dont_know,
                      NEW.current_meds_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_medication_history (
          id integer NOT NULL,
          master_id integer,
          current_meds_blank_yes_no_dont_know varchar,
          current_meds_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_medication_id integer
      );

      CREATE SEQUENCE ipa_medication_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_medication_history_id_seq OWNED BY ipa_medication_history.id;

      CREATE TABLE ipa_medications (
          id integer NOT NULL,
          master_id integer,
          current_meds_blank_yes_no_dont_know varchar,
          current_meds_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_medications_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_medications_id_seq OWNED BY ipa_medications.id;

      ALTER TABLE ONLY ipa_medications ALTER COLUMN id SET DEFAULT nextval('ipa_medications_id_seq'::regclass);
      ALTER TABLE ONLY ipa_medication_history ALTER COLUMN id SET DEFAULT nextval('ipa_medication_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_medication_history
          ADD CONSTRAINT ipa_medication_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_medications
          ADD CONSTRAINT ipa_medications_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_medication_history_on_master_id ON ipa_medication_history USING btree (master_id);


      CREATE INDEX index_ipa_medication_history_on_ipa_medication_id ON ipa_medication_history USING btree (ipa_medication_id);
      CREATE INDEX index_ipa_medication_history_on_user_id ON ipa_medication_history USING btree (user_id);

      CREATE INDEX index_ipa_medications_on_master_id ON ipa_medications USING btree (master_id);

      CREATE INDEX index_ipa_medications_on_user_id ON ipa_medications USING btree (user_id);

      CREATE TRIGGER ipa_medication_history_insert AFTER INSERT ON ipa_medications FOR EACH ROW EXECUTE PROCEDURE log_ipa_medication_update();
      CREATE TRIGGER ipa_medication_history_update AFTER UPDATE ON ipa_medications FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_medication_update();


      ALTER TABLE ONLY ipa_medications
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_medications
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_medication_history
          ADD CONSTRAINT fk_ipa_medication_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_medication_history
          ADD CONSTRAINT fk_ipa_medication_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_medication_history
          ADD CONSTRAINT fk_ipa_medication_history_ipa_medications FOREIGN KEY (ipa_medication_id) REFERENCES ipa_medications(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
