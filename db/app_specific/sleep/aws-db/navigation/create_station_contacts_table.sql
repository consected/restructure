
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_station_contacts first_name last_name role phone alt_phone email alt_email notes

      CREATE or REPLACE FUNCTION log_sleep_station_contact_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_station_contact_history
                  (
                      first_name,
                      last_name,
                      role,
                      select_availability,
                      phone,
                      alt_phone,
                      email,
                      alt_email,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_station_contact_id
                      )
                  SELECT
                      NEW.first_name,
                      NEW.last_name,
                      NEW.role,
                      NEW.phone,
                      NEW.select_availability,
                      NEW.alt_phone,
                      NEW.email,
                      NEW.alt_email,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_station_contact_history (
          id integer NOT NULL,
          first_name varchar,
          last_name varchar,
          role varchar,
          select_availability varchar,
          phone varchar,
          alt_phone varchar,
          email varchar,
          alt_email varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_station_contact_id integer
      );

      CREATE SEQUENCE sleep_station_contact_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_station_contact_history_id_seq OWNED BY sleep_station_contact_history.id;

      CREATE TABLE sleep_station_contacts (
          id integer NOT NULL,
          first_name varchar,
          last_name varchar,
          role varchar,
          select_availability varchar,
          phone varchar,
          alt_phone varchar,
          email varchar,
          alt_email varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_station_contacts_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_station_contacts_id_seq OWNED BY sleep_station_contacts.id;

      ALTER TABLE ONLY sleep_station_contacts ALTER COLUMN id SET DEFAULT nextval('sleep_station_contacts_id_seq'::regclass);
      ALTER TABLE ONLY sleep_station_contact_history ALTER COLUMN id SET DEFAULT nextval('sleep_station_contact_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_station_contact_history
          ADD CONSTRAINT sleep_station_contact_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_station_contacts
          ADD CONSTRAINT sleep_station_contacts_pkey PRIMARY KEY (id);



      CREATE INDEX index_sleep_station_contact_history_on_sleep_station_contact_id ON sleep_station_contact_history USING btree (sleep_station_contact_id);
      CREATE INDEX index_sleep_station_contact_history_on_user_id ON sleep_station_contact_history USING btree (user_id);


      CREATE INDEX index_sleep_station_contacts_on_user_id ON sleep_station_contacts USING btree (user_id);

      CREATE TRIGGER sleep_station_contact_history_insert AFTER INSERT ON sleep_station_contacts FOR EACH ROW EXECUTE PROCEDURE log_sleep_station_contact_update();
      CREATE TRIGGER sleep_station_contact_history_update AFTER UPDATE ON sleep_station_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_station_contact_update();


      ALTER TABLE ONLY sleep_station_contacts
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);



      ALTER TABLE ONLY sleep_station_contact_history
          ADD CONSTRAINT fk_sleep_station_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);





      ALTER TABLE ONLY sleep_station_contact_history
          ADD CONSTRAINT fk_sleep_station_contact_history_sleep_station_contacts FOREIGN KEY (sleep_station_contact_id) REFERENCES sleep_station_contacts(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
