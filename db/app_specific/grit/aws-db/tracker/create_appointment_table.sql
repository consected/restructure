
      BEGIN;

      CREATE OR REPLACE FUNCTION log_grit_appointment_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO grit_appointment_history
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
                    grit_appointment_id
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

      CREATE TABLE grit_appointment_history (
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
          grit_appointment_id integer
      );

      CREATE SEQUENCE grit_appointment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_appointment_history_id_seq OWNED BY grit_appointment_history.id;

      CREATE TABLE grit_appointments (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date,
          visit_end_date date,
          interventionist varchar,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_appointments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_appointments_id_seq OWNED BY grit_appointments.id;

      ALTER TABLE ONLY grit_appointments ALTER COLUMN id SET DEFAULT nextval('grit_appointments_id_seq'::regclass);
      ALTER TABLE ONLY grit_appointment_history ALTER COLUMN id SET DEFAULT nextval('grit_appointment_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_appointment_history
          ADD CONSTRAINT grit_appointment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_appointments
          ADD CONSTRAINT grit_appointments_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_appointment_history_on_master_id ON grit_appointment_history USING btree (master_id);


      CREATE INDEX index_grit_appointment_history_on_grit_appointment_id ON grit_appointment_history USING btree (grit_appointment_id);
      CREATE INDEX index_grit_appointment_history_on_user_id ON grit_appointment_history USING btree (user_id);

      CREATE INDEX index_grit_appointments_on_master_id ON grit_appointments USING btree (master_id);

      CREATE INDEX index_grit_appointments_on_user_id ON grit_appointments USING btree (user_id);

      CREATE TRIGGER grit_appointment_history_insert AFTER INSERT ON grit_appointments FOR EACH ROW EXECUTE PROCEDURE log_grit_appointment_update();
      CREATE TRIGGER grit_appointment_history_update AFTER UPDATE ON grit_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_appointment_update();


      ALTER TABLE ONLY grit_appointments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_appointments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_appointment_history
          ADD CONSTRAINT fk_grit_appointment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_appointment_history
          ADD CONSTRAINT fk_grit_appointment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_appointment_history
          ADD CONSTRAINT fk_grit_appointment_history_grit_appointments FOREIGN KEY (grit_appointment_id) REFERENCES grit_appointments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
