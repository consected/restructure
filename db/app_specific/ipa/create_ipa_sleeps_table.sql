
      BEGIN;

      DROP TABLE if exists ipa_ps_sleep_history CASCADE;
      DROP TABLE if exists ipa_ps_sleeps CASCADE;
      DROP FUNCTION if exists log_ipa_ps_sleep_update();


      COMMIT;

      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ipa_ps_sleeps false sleep_disorder_blank_yes_no_dont_know sleep_disorder_details sleep_apnea_device_no_yes sleep_apnea_device_details bed_and_wake_time_details

      CREATE FUNCTION log_ipa_ps_sleep_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_sleep_history
                  (
                      master_id,
                      sleep_disorder_blank_yes_no_dont_know,
                      sleep_disorder_details,
                      sleep_apnea_device_no_yes,
                      sleep_apnea_device_details,
                      bed_and_wake_time_details,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_sleep_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_disorder_blank_yes_no_dont_know,
                      NEW.sleep_disorder_details,
                      NEW.sleep_apnea_device_no_yes,
                      NEW.sleep_apnea_device_details,
                      NEW.bed_and_wake_time_details,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_sleep_history (
          id integer NOT NULL,
          master_id integer,
          sleep_disorder_blank_yes_no_dont_know varchar,
          sleep_disorder_details varchar,
          sleep_apnea_device_no_yes varchar,
          sleep_apnea_device_details varchar,
          bed_and_wake_time_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_sleep_id integer
      );

      CREATE SEQUENCE ipa_ps_sleep_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_sleep_history_id_seq OWNED BY ipa_ps_sleep_history.id;

      CREATE TABLE ipa_ps_sleeps (
          id integer NOT NULL,
          master_id integer,
          sleep_disorder_blank_yes_no_dont_know varchar,
          sleep_disorder_details varchar,
          sleep_apnea_device_no_yes varchar,
          sleep_apnea_device_details varchar,
          bed_and_wake_time_details varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_sleeps_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_sleeps_id_seq OWNED BY ipa_ps_sleeps.id;

      ALTER TABLE ONLY ipa_ps_sleeps ALTER COLUMN id SET DEFAULT nextval('ipa_ps_sleeps_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_sleep_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_sleep_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_sleep_history
          ADD CONSTRAINT ipa_ps_sleep_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_sleeps
          ADD CONSTRAINT ipa_ps_sleeps_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_sleep_history_on_master_id ON ipa_ps_sleep_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_sleep_history_on_ipa_ps_sleep_id ON ipa_ps_sleep_history USING btree (ipa_ps_sleep_id);
      CREATE INDEX index_ipa_ps_sleep_history_on_user_id ON ipa_ps_sleep_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_sleeps_on_master_id ON ipa_ps_sleeps USING btree (master_id);

      CREATE INDEX index_ipa_ps_sleeps_on_user_id ON ipa_ps_sleeps USING btree (user_id);

      CREATE TRIGGER ipa_ps_sleep_history_insert AFTER INSERT ON ipa_ps_sleeps FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_sleep_update();
      CREATE TRIGGER ipa_ps_sleep_history_update AFTER UPDATE ON ipa_ps_sleeps FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_sleep_update();


      ALTER TABLE ONLY ipa_ps_sleeps
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_sleeps
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_sleep_history
          ADD CONSTRAINT fk_ipa_ps_sleep_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_sleep_history
          ADD CONSTRAINT fk_ipa_ps_sleep_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_sleep_history
          ADD CONSTRAINT fk_ipa_ps_sleep_history_ipa_ps_sleeps FOREIGN KEY (ipa_ps_sleep_id) REFERENCES ipa_ps_sleeps(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
