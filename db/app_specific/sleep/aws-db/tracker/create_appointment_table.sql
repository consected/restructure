
      BEGIN;

      CREATE OR REPLACE FUNCTION log_sleep_appointment_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO sleep_appointment_history
                (
                    master_id,
                    visit_start_date,
                    visit_end_date,
                    interventionist,
                    select_status,
                    notes,
                    user_id,
                    created_at,
                    updated_at,
                    sleep_appointment_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.visit_start_date,
                    NEW.visit_end_date,
                    NEW.interventionist,
                    NEW.select_status,
                    NEW.notes,
                    NEW.user_id,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

      CREATE TABLE sleep_appointment_history (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date,
          visit_end_date date,
          interventionist varchar,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_appointment_id integer
      );

      CREATE SEQUENCE sleep_appointment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_appointment_history_id_seq OWNED BY sleep_appointment_history.id;

      CREATE TABLE sleep_appointments (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date unique,
          visit_end_date date,
          interventionist varchar,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_appointments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_appointments_id_seq OWNED BY sleep_appointments.id;

      ALTER TABLE ONLY sleep_appointments ALTER COLUMN id SET DEFAULT nextval('sleep_appointments_id_seq'::regclass);
      ALTER TABLE ONLY sleep_appointment_history ALTER COLUMN id SET DEFAULT nextval('sleep_appointment_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_appointment_history
          ADD CONSTRAINT sleep_appointment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_appointments
          ADD CONSTRAINT sleep_appointments_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_appointment_history_on_master_id ON sleep_appointment_history USING btree (master_id);


      CREATE INDEX index_sleep_appointment_history_on_sleep_appointment_id ON sleep_appointment_history USING btree (sleep_appointment_id);
      CREATE INDEX index_sleep_appointment_history_on_user_id ON sleep_appointment_history USING btree (user_id);

      CREATE INDEX index_sleep_appointments_on_master_id ON sleep_appointments USING btree (master_id);

      CREATE INDEX index_sleep_appointments_on_user_id ON sleep_appointments USING btree (user_id);

      CREATE TRIGGER sleep_appointment_history_insert AFTER INSERT ON sleep_appointments FOR EACH ROW EXECUTE PROCEDURE log_sleep_appointment_update();
      CREATE TRIGGER sleep_appointment_history_update AFTER UPDATE ON sleep_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_appointment_update();


      ALTER TABLE ONLY sleep_appointments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_appointments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_appointment_history
          ADD CONSTRAINT fk_sleep_appointment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_appointment_history
          ADD CONSTRAINT fk_sleep_appointment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_appointment_history
          ADD CONSTRAINT fk_sleep_appointment_history_sleep_appointments FOREIGN KEY (sleep_appointment_id) REFERENCES sleep_appointments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
