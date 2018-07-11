
      BEGIN;

      CREATE FUNCTION log_ipa_payment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_payment_history
                  (
                      master_id,
                      select_type,
                      sent_date,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_payment_id
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

      CREATE TABLE ipa_payment_history (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_payment_id integer
      );

      CREATE SEQUENCE ipa_payment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_payment_history_id_seq OWNED BY ipa_payment_history.id;

      CREATE TABLE ipa_payments (
          id integer NOT NULL,
          master_id integer,
          select_type varchar,
          sent_date date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_payments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_payments_id_seq OWNED BY ipa_payments.id;

      ALTER TABLE ONLY ipa_payments ALTER COLUMN id SET DEFAULT nextval('ipa_payments_id_seq'::regclass);
      ALTER TABLE ONLY ipa_payment_history ALTER COLUMN id SET DEFAULT nextval('ipa_payment_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_payment_history
          ADD CONSTRAINT ipa_payment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_payments
          ADD CONSTRAINT ipa_payments_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_payment_history_on_master_id ON ipa_payment_history USING btree (master_id);


      CREATE INDEX index_ipa_payment_history_on_ipa_payment_id ON ipa_payment_history USING btree (ipa_payment_id);
      CREATE INDEX index_ipa_payment_history_on_user_id ON ipa_payment_history USING btree (user_id);

      CREATE INDEX index_ipa_payments_on_master_id ON ipa_payments USING btree (master_id);

      CREATE INDEX index_ipa_payments_on_user_id ON ipa_payments USING btree (user_id);

      CREATE TRIGGER ipa_payment_history_insert AFTER INSERT ON ipa_payments FOR EACH ROW EXECUTE PROCEDURE log_ipa_payment_update();
      CREATE TRIGGER ipa_payment_history_update AFTER UPDATE ON ipa_payments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_payment_update();


      ALTER TABLE ONLY ipa_payments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_payments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_payment_history
          ADD CONSTRAINT fk_ipa_payment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_payment_history
          ADD CONSTRAINT fk_ipa_payment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_payment_history
          ADD CONSTRAINT fk_ipa_payment_history_ipa_payments FOREIGN KEY (ipa_payment_id) REFERENCES ipa_payments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
