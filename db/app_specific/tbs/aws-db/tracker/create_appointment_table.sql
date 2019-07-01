
      BEGIN;

      CREATE OR REPLACE FUNCTION log_tbs_appointment_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO tbs_appointment_history
                (
                    master_id,
                    visit_start_date,
                    visit_end_date,
                    select_status,
                    notes,
                    user_id,
                    created_at,
                    updated_at,
                    tbs_appointment_id
                    )
                SELECT
                    NEW.master_id,
                    NEW.visit_start_date,
                    NEW.visit_end_date,
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

      CREATE TABLE tbs_appointment_history (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date,
          visit_end_date date,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          tbs_appointment_id integer
      );

      CREATE SEQUENCE tbs_appointment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_appointment_history_id_seq OWNED BY tbs_appointment_history.id;

      CREATE TABLE tbs_appointments (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date unique,
          visit_end_date date,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE tbs_appointments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_appointments_id_seq OWNED BY tbs_appointments.id;

      ALTER TABLE ONLY tbs_appointments ALTER COLUMN id SET DEFAULT nextval('tbs_appointments_id_seq'::regclass);
      ALTER TABLE ONLY tbs_appointment_history ALTER COLUMN id SET DEFAULT nextval('tbs_appointment_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_appointment_history
          ADD CONSTRAINT tbs_appointment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_appointments
          ADD CONSTRAINT tbs_appointments_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_appointment_history_on_master_id ON tbs_appointment_history USING btree (master_id);


      CREATE INDEX index_tbs_appointment_history_on_tbs_appointment_id ON tbs_appointment_history USING btree (tbs_appointment_id);
      CREATE INDEX index_tbs_appointment_history_on_user_id ON tbs_appointment_history USING btree (user_id);

      CREATE INDEX index_tbs_appointments_on_master_id ON tbs_appointments USING btree (master_id);

      CREATE INDEX index_tbs_appointments_on_user_id ON tbs_appointments USING btree (user_id);

      CREATE TRIGGER tbs_appointment_history_insert AFTER INSERT ON tbs_appointments FOR EACH ROW EXECUTE PROCEDURE log_tbs_appointment_update();
      CREATE TRIGGER tbs_appointment_history_update AFTER UPDATE ON tbs_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_appointment_update();


      ALTER TABLE ONLY tbs_appointments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_appointments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_appointment_history
          ADD CONSTRAINT fk_tbs_appointment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_appointment_history
          ADD CONSTRAINT fk_tbs_appointment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_appointment_history
          ADD CONSTRAINT fk_tbs_appointment_history_tbs_appointments FOREIGN KEY (tbs_appointment_id) REFERENCES tbs_appointments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
