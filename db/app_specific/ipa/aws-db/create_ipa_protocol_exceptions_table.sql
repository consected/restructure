
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_protocol_exceptions exception_date exception_description risks_and_benefits_notes informed_consent_notes

      CREATE FUNCTION log_ipa_protocol_exception_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_protocol_exception_history
                  (
                      master_id,
                      exception_date,
                      exception_description,
                      risks_and_benefits_notes,
                      informed_consent_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_protocol_exception_id
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

      CREATE TABLE ipa_protocol_exception_history (
          id integer NOT NULL,
          master_id integer,
          exception_date date,
          exception_description varchar,
          risks_and_benefits_notes varchar,
          informed_consent_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_protocol_exception_id integer
      );

      CREATE SEQUENCE ipa_protocol_exception_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_protocol_exception_history_id_seq OWNED BY ipa_protocol_exception_history.id;

      CREATE TABLE ipa_protocol_exceptions (
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
      CREATE SEQUENCE ipa_protocol_exceptions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_protocol_exceptions_id_seq OWNED BY ipa_protocol_exceptions.id;

      ALTER TABLE ONLY ipa_protocol_exceptions ALTER COLUMN id SET DEFAULT nextval('ipa_protocol_exceptions_id_seq'::regclass);
      ALTER TABLE ONLY ipa_protocol_exception_history ALTER COLUMN id SET DEFAULT nextval('ipa_protocol_exception_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_protocol_exception_history
          ADD CONSTRAINT ipa_protocol_exception_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_protocol_exceptions
          ADD CONSTRAINT ipa_protocol_exceptions_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_protocol_exception_history_on_master_id ON ipa_protocol_exception_history USING btree (master_id);


      CREATE INDEX index_ipa_protocol_exception_history_on_ipa_protocol_exception_id ON ipa_protocol_exception_history USING btree (ipa_protocol_exception_id);
      CREATE INDEX index_ipa_protocol_exception_history_on_user_id ON ipa_protocol_exception_history USING btree (user_id);

      CREATE INDEX index_ipa_protocol_exceptions_on_master_id ON ipa_protocol_exceptions USING btree (master_id);

      CREATE INDEX index_ipa_protocol_exceptions_on_user_id ON ipa_protocol_exceptions USING btree (user_id);

      CREATE TRIGGER ipa_protocol_exception_history_insert AFTER INSERT ON ipa_protocol_exceptions FOR EACH ROW EXECUTE PROCEDURE log_ipa_protocol_exception_update();
      CREATE TRIGGER ipa_protocol_exception_history_update AFTER UPDATE ON ipa_protocol_exceptions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_protocol_exception_update();


      ALTER TABLE ONLY ipa_protocol_exceptions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_protocol_exceptions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_protocol_exception_history
          ADD CONSTRAINT fk_ipa_protocol_exception_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_protocol_exception_history
          ADD CONSTRAINT fk_ipa_protocol_exception_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_protocol_exception_history
          ADD CONSTRAINT fk_ipa_protocol_exception_history_ipa_protocol_exceptions FOREIGN KEY (ipa_protocol_exception_id) REFERENCES ipa_protocol_exceptions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
