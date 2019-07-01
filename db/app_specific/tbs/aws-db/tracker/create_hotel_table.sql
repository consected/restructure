
      BEGIN;

      CREATE FUNCTION log_tbs_hotel_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO tbs_hotel_history
                  (
                      master_id,
                      hotel,
                      room_number,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      tbs_hotel_id,
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

      CREATE TABLE tbs_hotel_history (
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
          tbs_hotel_id integer
      );

      CREATE SEQUENCE tbs_hotel_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_hotel_history_id_seq OWNED BY tbs_hotel_history.id;

      CREATE TABLE tbs_hotels (
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
      CREATE SEQUENCE tbs_hotels_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_hotels_id_seq OWNED BY tbs_hotels.id;

      ALTER TABLE ONLY tbs_hotels ALTER COLUMN id SET DEFAULT nextval('tbs_hotels_id_seq'::regclass);
      ALTER TABLE ONLY tbs_hotel_history ALTER COLUMN id SET DEFAULT nextval('tbs_hotel_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_hotel_history
          ADD CONSTRAINT tbs_hotel_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_hotels
          ADD CONSTRAINT tbs_hotels_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_hotel_history_on_master_id ON tbs_hotel_history USING btree (master_id);


      CREATE INDEX index_tbs_hotel_history_on_tbs_hotel_id ON tbs_hotel_history USING btree (tbs_hotel_id);
      CREATE INDEX index_tbs_hotel_history_on_user_id ON tbs_hotel_history USING btree (user_id);

      CREATE INDEX index_tbs_hotels_on_master_id ON tbs_hotels USING btree (master_id);

      CREATE INDEX index_tbs_hotels_on_user_id ON tbs_hotels USING btree (user_id);

      CREATE TRIGGER tbs_hotel_history_insert AFTER INSERT ON tbs_hotels FOR EACH ROW EXECUTE PROCEDURE log_tbs_hotel_update();
      CREATE TRIGGER tbs_hotel_history_update AFTER UPDATE ON tbs_hotels FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_hotel_update();


      ALTER TABLE ONLY tbs_hotels
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_hotels
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_hotel_history
          ADD CONSTRAINT fk_tbs_hotel_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_hotel_history
          ADD CONSTRAINT fk_tbs_hotel_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_hotel_history
          ADD CONSTRAINT fk_tbs_hotel_history_tbs_hotels FOREIGN KEY (tbs_hotel_id) REFERENCES tbs_hotels(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
