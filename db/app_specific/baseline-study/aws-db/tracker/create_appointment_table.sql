
      BEGIN;

      CREATE OR REPLACE FUNCTION log_${target_name_us}_appointment_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO ${target_name_us}_appointment_history
                (
                    master_id,
                    visit_start_date,
                    visit_end_date,
                    select_status,
                    notes,
                    user_id,
                    created_at,
                    updated_at,
                    ${target_name_us}_appointment_id
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

      CREATE TABLE ${target_name_us}_appointment_history (
          id integer NOT NULL,
          master_id integer,
          visit_start_date date,
          visit_end_date date,
          select_status varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_appointment_id integer
      );

      CREATE SEQUENCE ${target_name_us}_appointment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_appointment_history_id_seq OWNED BY ${target_name_us}_appointment_history.id;

      CREATE TABLE ${target_name_us}_appointments (
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
      CREATE SEQUENCE ${target_name_us}_appointments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_appointments_id_seq OWNED BY ${target_name_us}_appointments.id;

      ALTER TABLE ONLY ${target_name_us}_appointments ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_appointments_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_appointment_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_appointment_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_appointment_history
          ADD CONSTRAINT ${target_name_us}_appointment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_appointments
          ADD CONSTRAINT ${target_name_us}_appointments_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_appointment_history_on_master_id ON ${target_name_us}_appointment_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_appointment_history_on_${target_name_us}_appointment_id ON ${target_name_us}_appointment_history USING btree (${target_name_us}_appointment_id);
      CREATE INDEX index_${target_name_us}_appointment_history_on_user_id ON ${target_name_us}_appointment_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_appointments_on_master_id ON ${target_name_us}_appointments USING btree (master_id);

      CREATE INDEX index_${target_name_us}_appointments_on_user_id ON ${target_name_us}_appointments USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_appointment_history_insert AFTER INSERT ON ${target_name_us}_appointments FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_appointment_update();
      CREATE TRIGGER ${target_name_us}_appointment_history_update AFTER UPDATE ON ${target_name_us}_appointments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_appointment_update();


      ALTER TABLE ONLY ${target_name_us}_appointments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_appointments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_appointment_history
          ADD CONSTRAINT fk_${target_name_us}_appointment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_appointment_history
          ADD CONSTRAINT fk_${target_name_us}_appointment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_appointment_history
          ADD CONSTRAINT fk_${target_name_us}_appointment_history_${target_name_us}_appointments FOREIGN KEY (${target_name_us}_appointment_id) REFERENCES ${target_name_us}_appointments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
