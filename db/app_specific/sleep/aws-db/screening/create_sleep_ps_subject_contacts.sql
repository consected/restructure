set search_path=sleep, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ps_subject_contacts follow_up_date follow_up_time notes

      CREATE FUNCTION log_sleep_ps_subject_contact_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_ps_subject_contact_history
                  (
                      master_id,
                      follow_up_date,
                      follow_up_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_ps_subject_contact_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.follow_up_date,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_ps_subject_contact_history (
          id integer NOT NULL,
          master_id integer,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_ps_subject_contact_id integer
      );

      CREATE SEQUENCE sleep_ps_subject_contact_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_subject_contact_history_id_seq OWNED BY sleep_ps_subject_contact_history.id;

      CREATE TABLE sleep_ps_subject_contacts (
          id integer NOT NULL,
          master_id integer,
          follow_up_date date,
          follow_up_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_ps_subject_contacts_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_ps_subject_contacts_id_seq OWNED BY sleep_ps_subject_contacts.id;

      ALTER TABLE ONLY sleep_ps_subject_contacts ALTER COLUMN id SET DEFAULT nextval('sleep_ps_subject_contacts_id_seq'::regclass);
      ALTER TABLE ONLY sleep_ps_subject_contact_history ALTER COLUMN id SET DEFAULT nextval('sleep_ps_subject_contact_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_ps_subject_contact_history
          ADD CONSTRAINT sleep_ps_subject_contact_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_ps_subject_contacts
          ADD CONSTRAINT sleep_ps_subject_contacts_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_ps_subject_contact_history_on_master_id ON sleep_ps_subject_contact_history USING btree (master_id);


      CREATE INDEX index_sleep_ps_subject_contact_history_on_sleep_ps_subject_contact_id ON sleep_ps_subject_contact_history USING btree (sleep_ps_subject_contact_id);
      CREATE INDEX index_sleep_ps_subject_contact_history_on_user_id ON sleep_ps_subject_contact_history USING btree (user_id);

      CREATE INDEX index_sleep_ps_subject_contacts_on_master_id ON sleep_ps_subject_contacts USING btree (master_id);

      CREATE INDEX index_sleep_ps_subject_contacts_on_user_id ON sleep_ps_subject_contacts USING btree (user_id);

      CREATE TRIGGER sleep_ps_subject_contact_history_insert AFTER INSERT ON sleep_ps_subject_contacts FOR EACH ROW EXECUTE PROCEDURE log_sleep_ps_subject_contact_update();
      CREATE TRIGGER sleep_ps_subject_contact_history_update AFTER UPDATE ON sleep_ps_subject_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ps_subject_contact_update();


      ALTER TABLE ONLY sleep_ps_subject_contacts
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_ps_subject_contacts
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_ps_subject_contact_history
          ADD CONSTRAINT fk_sleep_ps_subject_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_ps_subject_contact_history
          ADD CONSTRAINT fk_sleep_ps_subject_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_ps_subject_contact_history
          ADD CONSTRAINT fk_sleep_ps_subject_contact_history_sleep_ps_subject_contacts FOREIGN KEY (sleep_ps_subject_contact_id) REFERENCES sleep_ps_subject_contacts(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
