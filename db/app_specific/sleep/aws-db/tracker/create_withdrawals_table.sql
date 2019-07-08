
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_withdrawals select_subject_withdrew_reason select_investigator_terminated lost_to_follow_up_no_yes no_longer_participating_no_yes notes

      CREATE FUNCTION log_sleep_withdrawal_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO sleep_withdrawal_history
                  (
                      master_id,
                      select_subject_withdrew_reason,
                      select_investigator_terminated,
                      lost_to_follow_up_no_yes,
                      no_longer_participating_no_yes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      sleep_withdrawal_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_subject_withdrew_reason,
                      NEW.select_investigator_terminated,
                      NEW.lost_to_follow_up_no_yes,
                      NEW.no_longer_participating_no_yes,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE sleep_withdrawal_history (
          id integer NOT NULL,
          master_id integer,
          select_subject_withdrew_reason varchar,
          select_investigator_terminated varchar,
          lost_to_follow_up_no_yes varchar,
          no_longer_participating_no_yes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          sleep_withdrawal_id integer
      );

      CREATE SEQUENCE sleep_withdrawal_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_withdrawal_history_id_seq OWNED BY sleep_withdrawal_history.id;

      CREATE TABLE sleep_withdrawals (
          id integer NOT NULL,
          master_id integer,
          select_subject_withdrew_reason varchar,
          select_investigator_terminated varchar,
          lost_to_follow_up_no_yes varchar,
          no_longer_participating_no_yes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE sleep_withdrawals_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE sleep_withdrawals_id_seq OWNED BY sleep_withdrawals.id;

      ALTER TABLE ONLY sleep_withdrawals ALTER COLUMN id SET DEFAULT nextval('sleep_withdrawals_id_seq'::regclass);
      ALTER TABLE ONLY sleep_withdrawal_history ALTER COLUMN id SET DEFAULT nextval('sleep_withdrawal_history_id_seq'::regclass);

      ALTER TABLE ONLY sleep_withdrawal_history
          ADD CONSTRAINT sleep_withdrawal_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY sleep_withdrawals
          ADD CONSTRAINT sleep_withdrawals_pkey PRIMARY KEY (id);

      CREATE INDEX index_sleep_withdrawal_history_on_master_id ON sleep_withdrawal_history USING btree (master_id);


      CREATE INDEX index_sleep_withdrawal_history_on_sleep_withdrawal_id ON sleep_withdrawal_history USING btree (sleep_withdrawal_id);
      CREATE INDEX index_sleep_withdrawal_history_on_user_id ON sleep_withdrawal_history USING btree (user_id);

      CREATE INDEX index_sleep_withdrawals_on_master_id ON sleep_withdrawals USING btree (master_id);

      CREATE INDEX index_sleep_withdrawals_on_user_id ON sleep_withdrawals USING btree (user_id);

      CREATE TRIGGER sleep_withdrawal_history_insert AFTER INSERT ON sleep_withdrawals FOR EACH ROW EXECUTE PROCEDURE log_sleep_withdrawal_update();
      CREATE TRIGGER sleep_withdrawal_history_update AFTER UPDATE ON sleep_withdrawals FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_withdrawal_update();


      ALTER TABLE ONLY sleep_withdrawals
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY sleep_withdrawals
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY sleep_withdrawal_history
          ADD CONSTRAINT fk_sleep_withdrawal_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY sleep_withdrawal_history
          ADD CONSTRAINT fk_sleep_withdrawal_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY sleep_withdrawal_history
          ADD CONSTRAINT fk_sleep_withdrawal_history_sleep_withdrawals FOREIGN KEY (sleep_withdrawal_id) REFERENCES sleep_withdrawals(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
