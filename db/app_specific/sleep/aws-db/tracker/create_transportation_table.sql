
      BEGIN;

      CREATE FUNCTION log_sleep_transportation_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_transportation_history
                  (
                      master_id,
                      travel_date,
                      travel_confirmed_no_yes,
                      select_direction,
                      origin_city_and_state,
                      destination_city_and_state,
                      select_mode_of_transport,
                      airline,
                      flight_number,
                      departure_time,
                      arrival_time,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_transportation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.travel_date,
                      NEW.travel_confirmed_no_yes,
                      NEW.select_direction,
                      NEW.origin_city_and_state,
                      NEW.destination_city_and_state,
                      NEW.select_mode_of_transport,
                      NEW.airline,
                      NEW.flight_number,
                      NEW.departure_time,
                      NEW.arrival_time,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_transportation_history (
          id integer NOT NULL,
          master_id integer,
          travel_date date,
          travel_confirmed_no_yes varchar,
          select_direction varchar,
          origin_city_and_state varchar,
          destination_city_and_state varchar,
          select_mode_of_transport varchar,
          airline varchar,
          flight_number varchar,
          departure_time varchar,
          arrival_time varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_transportation_id integer
      );

      CREATE SEQUENCE sleep_transportation_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_transportation_history_id_seq OWNED BY sleep_transportation_history.id;

      CREATE TABLE sleep_transportations (
          id integer NOT NULL,
          master_id integer,
          travel_date date,
          travel_confirmed_no_yes varchar,
          select_direction varchar,
          origin_city_and_state varchar,
          destination_city_and_state varchar,
          select_mode_of_transport varchar,
          airline varchar,
          flight_number varchar,
          departure_time varchar,
          arrival_time varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_transportations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_transportations_id_seq OWNED BY sleep_transportations.id;

      ALTER TABLE ONLY sleep_transportations ALTER COLUMN id SET DEFAULT nextval('sleep_transportations_id_seq'::regclass);
      ALTER TABLE ONLY sleep_transportation_history ALTER COLUMN id SET DEFAULT nextval('sleep_transportation_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_transportation_history
          ADD CONSTRAINT sleep_transportation_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_transportations
          ADD CONSTRAINT sleep_transportations_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_transportation_history_on_master_id ON sleep_transportation_history USING btree (master_id);


      CREATE INDEX index_sleep_transportation_history_on_sleep_transportation_id ON sleep_transportation_history USING btree (sleep_transportation_id);
      CREATE INDEX index_sleep_transportation_history_on_user_id ON sleep_transportation_history USING btree (user_id);

      CREATE INDEX index_sleep_transportations_on_master_id ON sleep_transportations USING btree (master_id);

      CREATE INDEX index_sleep_transportations_on_user_id ON sleep_transportations USING btree (user_id);

      CREATE TRIGGER sleep_transportation_history_insert AFTER INSERT ON sleep_transportations FOR EACH ROW EXECUTE PROCEDURE log_sleep_transportation_update();
      CREATE TRIGGER sleep_transportation_history_update AFTER UPDATE ON sleep_transportations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_transportation_update();


      ALTER TABLE ONLY sleep_transportations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_transportations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_transportation_history
          ADD CONSTRAINT fk_sleep_transportation_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_transportation_history
          ADD CONSTRAINT fk_sleep_transportation_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_transportation_history
          ADD CONSTRAINT fk_sleep_transportation_history_sleep_transportations FOREIGN KEY (sleep_transportation_id) REFERENCES sleep_transportations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
