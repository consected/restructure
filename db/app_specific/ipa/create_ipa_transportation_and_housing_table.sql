
      BEGIN;

      CREATE FUNCTION log_ipa_transportation_and_housing_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_transportation_and_housing_history
                  (
                      master_id,
                      select_navigator,
                      arrival_date,
                      departure_date,
                      travel_confirmed_no_yes,
                      origin_city_and_state,
                      airline,
                      flight_number,
                      departure_from_origin_time,
                      arrival_in_boston_time,
                      departure_from_boston_time,
                      arrival_in_origin_time,
                      hotel_confirmed_no_yes,
                      hotel,
                      hotel_room_number,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_transportation_and_housing_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_navigator,
                      NEW.arrival_date,
                      NEW.departure_date,
                      NEW.travel_confirmed_no_yes,
                      NEW.origin_city_and_state,
                      NEW.airline,
                      NEW.flight_number,
                      NEW.departure_from_origin_time,
                      NEW.arrival_in_boston_time,
                      NEW.departure_from_boston_time,
                      NEW.arrival_in_origin_time,
                      NEW.hotel_confirmed_no_yes,
                      NEW.hotel,
                      NEW.hotel_room_number,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_transportation_and_housing_history (
          id integer NOT NULL,
          master_id integer,
          select_navigator varchar,
          arrival_date date,
          departure_date date,
          travel_confirmed_no_yes varchar,
          origin_city_and_state varchar,
          airline varchar,
          flight_number varchar,
          departure_from_origin_time varchar,
          arrival_in_boston_time varchar,
          departure_from_boston_time varchar,
          arrival_in_origin_time varchar,
          hotel_confirmed_no_yes varchar,
          hotel varchar,
          hotel_room_number varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_transportation_and_housing_id integer
      );

      CREATE SEQUENCE ipa_transportation_and_housing_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_transportation_and_housing_history_id_seq OWNED BY ipa_transportation_and_housing_history.id;

      CREATE TABLE ipa_transportation_and_housings (
          id integer NOT NULL,
          master_id integer,
          select_navigator varchar,
          arrival_date date,
          departure_date date,
          travel_confirmed_no_yes varchar,
          origin_city_and_state varchar,
          airline varchar,
          flight_number varchar,
          departure_from_origin_time varchar,
          arrival_in_boston_time varchar,
          departure_from_boston_time varchar,
          arrival_in_origin_time varchar,
          hotel_confirmed_no_yes varchar,
          hotel varchar,
          hotel_room_number varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_transportation_and_housings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_transportation_and_housings_id_seq OWNED BY ipa_transportation_and_housings.id;

      ALTER TABLE ONLY ipa_transportation_and_housings ALTER COLUMN id SET DEFAULT nextval('ipa_transportation_and_housings_id_seq'::regclass);
      ALTER TABLE ONLY ipa_transportation_and_housing_history ALTER COLUMN id SET DEFAULT nextval('ipa_transportation_and_housing_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_transportation_and_housing_history
          ADD CONSTRAINT ipa_transportation_and_housing_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_transportation_and_housings
          ADD CONSTRAINT ipa_transportation_and_housings_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_transportation_and_housing_history_on_master_id ON ipa_transportation_and_housing_history USING btree (master_id);


      CREATE INDEX index_ipa_transportation_and_housing_history_on_ipa_transportation_and_housing_id ON ipa_transportation_and_housing_history USING btree (ipa_transportation_and_housing_id);
      CREATE INDEX index_ipa_transportation_and_housing_history_on_user_id ON ipa_transportation_and_housing_history USING btree (user_id);

      CREATE INDEX index_ipa_transportation_and_housings_on_master_id ON ipa_transportation_and_housings USING btree (master_id);

      CREATE INDEX index_ipa_transportation_and_housings_on_user_id ON ipa_transportation_and_housings USING btree (user_id);

      CREATE TRIGGER ipa_transportation_and_housing_history_insert AFTER INSERT ON ipa_transportation_and_housings FOR EACH ROW EXECUTE PROCEDURE log_ipa_transportation_and_housing_update();
      CREATE TRIGGER ipa_transportation_and_housing_history_update AFTER UPDATE ON ipa_transportation_and_housings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_transportation_and_housing_update();


      ALTER TABLE ONLY ipa_transportation_and_housings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_transportation_and_housings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_transportation_and_housing_history
          ADD CONSTRAINT fk_ipa_transportation_and_housing_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_transportation_and_housing_history
          ADD CONSTRAINT fk_ipa_transportation_and_housing_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_transportation_and_housing_history
          ADD CONSTRAINT fk_ipa_transportation_and_housing_history_ipa_transportation_and_housings FOREIGN KEY (ipa_transportation_and_housing_id) REFERENCES ipa_transportation_and_housings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
