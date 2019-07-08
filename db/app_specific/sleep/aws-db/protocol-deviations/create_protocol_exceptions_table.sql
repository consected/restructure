
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_protocol_exceptions exception_date exception_description risks_and_benefits_notes informed_consent_notes

      CREATE FUNCTION log_sleep_protocol_exception_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_protocol_exception_history
                  (
                      master_id,
                      exception_date,
                      exception_description,
                      risks_and_benefits_notes,
                      informed_consent_notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_protocol_exception_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.exception_date,
                      NEW.exception_description,
                      NEW.risks_and_benefits_notes,
                      NEW.informed_consent_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_protocol_exception_history (
          id integer NOT NULL,
          master_id integer,
          exception_date date,
          exception_description varchar,
          risks_and_benefits_notes varchar,
          informed_consent_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_protocol_exception_id integer
      );

      CREATE SEQUENCE sleep_protocol_exception_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_protocol_exception_history_id_seq OWNED BY sleep_protocol_exception_history.id;

      CREATE TABLE sleep_protocol_exceptions (
          id integer NOT NULL,
          master_id integer,
          exception_date date,
          exception_description varchar,
          risks_and_benefits_notes varchar,
          informed_consent_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_protocol_exceptions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_protocol_exceptions_id_seq OWNED BY sleep_protocol_exceptions.id;

      ALTER TABLE ONLY sleep_protocol_exceptions ALTER COLUMN id SET DEFAULT nextval('sleep_protocol_exceptions_id_seq'::regclass);
      ALTER TABLE ONLY sleep_protocol_exception_history ALTER COLUMN id SET DEFAULT nextval('sleep_protocol_exception_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_protocol_exception_history
          ADD CONSTRAINT sleep_protocol_exception_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_protocol_exceptions
          ADD CONSTRAINT sleep_protocol_exceptions_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_protocol_exception_history_on_master_id ON sleep_protocol_exception_history USING btree (master_id);


      CREATE INDEX index_sleep_protocol_exception_history_on_sleep_protocol_exception_id ON sleep_protocol_exception_history USING btree (sleep_protocol_exception_id);
      CREATE INDEX index_sleep_protocol_exception_history_on_user_id ON sleep_protocol_exception_history USING btree (user_id);

      CREATE INDEX index_sleep_protocol_exceptions_on_master_id ON sleep_protocol_exceptions USING btree (master_id);

      CREATE INDEX index_sleep_protocol_exceptions_on_user_id ON sleep_protocol_exceptions USING btree (user_id);

      CREATE TRIGGER sleep_protocol_exception_history_insert AFTER INSERT ON sleep_protocol_exceptions FOR EACH ROW EXECUTE PROCEDURE log_sleep_protocol_exception_update();
      CREATE TRIGGER sleep_protocol_exception_history_update AFTER UPDATE ON sleep_protocol_exceptions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_protocol_exception_update();


      ALTER TABLE ONLY sleep_protocol_exceptions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_protocol_exceptions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_protocol_exception_history
          ADD CONSTRAINT fk_sleep_protocol_exception_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_protocol_exception_history
          ADD CONSTRAINT fk_sleep_protocol_exception_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_protocol_exception_history
          ADD CONSTRAINT fk_sleep_protocol_exception_history_sleep_protocol_exceptions FOREIGN KEY (sleep_protocol_exception_id) REFERENCES sleep_protocol_exceptions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
