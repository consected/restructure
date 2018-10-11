
      BEGIN;

      CREATE FUNCTION log_ipa_hotel_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_hotel_history
                  (
                      master_id,
                      hotel,
                      room_number,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_hotel_id,
                      check_in_date,
                      check_in_time,
                      check_out_date,
                      check_out_time
                      )
                  SELECT
                      NEW.master_id,
                      NEW.hotel,
                      NEW.room_number,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id,
                      NEW.check_in_date,
                      NEW.check_in_time,
                      NEW.check_out_date,
                      NEW.check_out_time
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_hotel_history (
          id integer NOT NULL,
          master_id integer,
          hotel varchar,
          check_in_date date,
          check_in_time time,
          room_number varchar,
          check_out_date date,
          check_out_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_hotel_id integer
      );

      CREATE SEQUENCE ipa_hotel_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_hotel_history_id_seq OWNED BY ipa_hotel_history.id;

      CREATE TABLE ipa_hotels (
          id integer NOT NULL,
          master_id integer,
          hotel varchar,
          check_in_date date,
          check_in_time time,
          room_number varchar,
          check_out_date date,
          check_out_time time,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_hotels_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_hotels_id_seq OWNED BY ipa_hotels.id;

      ALTER TABLE ONLY ipa_hotels ALTER COLUMN id SET DEFAULT nextval('ipa_hotels_id_seq'::regclass);
      ALTER TABLE ONLY ipa_hotel_history ALTER COLUMN id SET DEFAULT nextval('ipa_hotel_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_hotel_history
          ADD CONSTRAINT ipa_hotel_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_hotels
          ADD CONSTRAINT ipa_hotels_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_hotel_history_on_master_id ON ipa_hotel_history USING btree (master_id);


      CREATE INDEX index_ipa_hotel_history_on_ipa_hotel_id ON ipa_hotel_history USING btree (ipa_hotel_id);
      CREATE INDEX index_ipa_hotel_history_on_user_id ON ipa_hotel_history USING btree (user_id);

      CREATE INDEX index_ipa_hotels_on_master_id ON ipa_hotels USING btree (master_id);

      CREATE INDEX index_ipa_hotels_on_user_id ON ipa_hotels USING btree (user_id);

      CREATE TRIGGER ipa_hotel_history_insert AFTER INSERT ON ipa_hotels FOR EACH ROW EXECUTE PROCEDURE log_ipa_hotel_update();
      CREATE TRIGGER ipa_hotel_history_update AFTER UPDATE ON ipa_hotels FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_hotel_update();


      ALTER TABLE ONLY ipa_hotels
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_hotels
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_hotel_history
          ADD CONSTRAINT fk_ipa_hotel_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_hotel_history
          ADD CONSTRAINT fk_ipa_hotel_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_hotel_history
          ADD CONSTRAINT fk_ipa_hotel_history_ipa_hotels FOREIGN KEY (ipa_hotel_id) REFERENCES ipa_hotels(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
