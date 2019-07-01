
      BEGIN;

      CREATE FUNCTION log_tbs_transportation_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO tbs_transportation_history
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
                      tbs_transportation_id
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

      CREATE TABLE tbs_transportation_history (
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
          tbs_transportation_id integer
      );

      CREATE SEQUENCE tbs_transportation_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_transportation_history_id_seq OWNED BY tbs_transportation_history.id;

      CREATE TABLE tbs_transportations (
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
      CREATE SEQUENCE tbs_transportations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_transportations_id_seq OWNED BY tbs_transportations.id;

      ALTER TABLE ONLY tbs_transportations ALTER COLUMN id SET DEFAULT nextval('tbs_transportations_id_seq'::regclass);
      ALTER TABLE ONLY tbs_transportation_history ALTER COLUMN id SET DEFAULT nextval('tbs_transportation_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_transportation_history
          ADD CONSTRAINT tbs_transportation_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_transportations
          ADD CONSTRAINT tbs_transportations_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_transportation_history_on_master_id ON tbs_transportation_history USING btree (master_id);


      CREATE INDEX index_tbs_transportation_history_on_tbs_transportation_id ON tbs_transportation_history USING btree (tbs_transportation_id);
      CREATE INDEX index_tbs_transportation_history_on_user_id ON tbs_transportation_history USING btree (user_id);

      CREATE INDEX index_tbs_transportations_on_master_id ON tbs_transportations USING btree (master_id);

      CREATE INDEX index_tbs_transportations_on_user_id ON tbs_transportations USING btree (user_id);

      CREATE TRIGGER tbs_transportation_history_insert AFTER INSERT ON tbs_transportations FOR EACH ROW EXECUTE PROCEDURE log_tbs_transportation_update();
      CREATE TRIGGER tbs_transportation_history_update AFTER UPDATE ON tbs_transportations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_transportation_update();


      ALTER TABLE ONLY tbs_transportations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_transportations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_transportation_history
          ADD CONSTRAINT fk_tbs_transportation_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_transportation_history
          ADD CONSTRAINT fk_tbs_transportation_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_transportation_history
          ADD CONSTRAINT fk_tbs_transportation_history_tbs_transportations FOREIGN KEY (tbs_transportation_id) REFERENCES tbs_transportations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
