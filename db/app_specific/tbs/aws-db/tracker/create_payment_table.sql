
      BEGIN;

      CREATE FUNCTION log_tbs_payment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO tbs_payment_history
                  (
                      master_id,
                      select_type,
                      sent_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      tbs_payment_id
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

      CREATE TABLE tbs_payment_history (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          tbs_payment_id integer
      );

      CREATE SEQUENCE tbs_payment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_payment_history_id_seq OWNED BY tbs_payment_history.id;

      CREATE TABLE tbs_payments (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE tbs_payments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE tbs_payments_id_seq OWNED BY tbs_payments.id;

      ALTER TABLE ONLY tbs_payments ALTER COLUMN id SET DEFAULT nextval('tbs_payments_id_seq'::regclass);
      ALTER TABLE ONLY tbs_payment_history ALTER COLUMN id SET DEFAULT nextval('tbs_payment_history_id_seq'::regclass);

      ALTER TABLE ONLY tbs_payment_history
          ADD CONSTRAINT tbs_payment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY tbs_payments
          ADD CONSTRAINT tbs_payments_pkey PRIMARY KEY (id);

      CREATE INDEX index_tbs_payment_history_on_master_id ON tbs_payment_history USING btree (master_id);


      CREATE INDEX index_tbs_payment_history_on_tbs_payment_id ON tbs_payment_history USING btree (tbs_payment_id);
      CREATE INDEX index_tbs_payment_history_on_user_id ON tbs_payment_history USING btree (user_id);

      CREATE INDEX index_tbs_payments_on_master_id ON tbs_payments USING btree (master_id);

      CREATE INDEX index_tbs_payments_on_user_id ON tbs_payments USING btree (user_id);

      CREATE TRIGGER tbs_payment_history_insert AFTER INSERT ON tbs_payments FOR EACH ROW EXECUTE PROCEDURE log_tbs_payment_update();
      CREATE TRIGGER tbs_payment_history_update AFTER UPDATE ON tbs_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tbs_payment_update();


      ALTER TABLE ONLY tbs_payments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY tbs_payments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY tbs_payment_history
          ADD CONSTRAINT fk_tbs_payment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY tbs_payment_history
          ADD CONSTRAINT fk_tbs_payment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY tbs_payment_history
          ADD CONSTRAINT fk_tbs_payment_history_tbs_payments FOREIGN KEY (tbs_payment_id) REFERENCES tbs_payments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
