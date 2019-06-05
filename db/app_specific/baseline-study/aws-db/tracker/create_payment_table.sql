
      BEGIN;

      CREATE FUNCTION log_${target_name_us}_payment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_payment_history
                  (
                      master_id,
                      select_type,
                      sent_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_payment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_type,
                      NEW.sent_date,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_payment_history (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_payment_id integer
      );

      CREATE SEQUENCE ${target_name_us}_payment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_payment_history_id_seq OWNED BY ${target_name_us}_payment_history.id;

      CREATE TABLE ${target_name_us}_payments (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_payments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_payments_id_seq OWNED BY ${target_name_us}_payments.id;

      ALTER TABLE ONLY ${target_name_us}_payments ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_payments_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_payment_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_payment_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_payment_history
          ADD CONSTRAINT ${target_name_us}_payment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_payments
          ADD CONSTRAINT ${target_name_us}_payments_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_payment_history_on_master_id ON ${target_name_us}_payment_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_payment_history_on_${target_name_us}_payment_id ON ${target_name_us}_payment_history USING btree (${target_name_us}_payment_id);
      CREATE INDEX index_${target_name_us}_payment_history_on_user_id ON ${target_name_us}_payment_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_payments_on_master_id ON ${target_name_us}_payments USING btree (master_id);

      CREATE INDEX index_${target_name_us}_payments_on_user_id ON ${target_name_us}_payments USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_payment_history_insert AFTER INSERT ON ${target_name_us}_payments FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_payment_update();
      CREATE TRIGGER ${target_name_us}_payment_history_update AFTER UPDATE ON ${target_name_us}_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_payment_update();


      ALTER TABLE ONLY ${target_name_us}_payments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_payments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_payment_history
          ADD CONSTRAINT fk_${target_name_us}_payment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_payment_history
          ADD CONSTRAINT fk_${target_name_us}_payment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_payment_history
          ADD CONSTRAINT fk_${target_name_us}_payment_history_${target_name_us}_payments FOREIGN KEY (${target_name_us}_payment_id) REFERENCES ${target_name_us}_payments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
