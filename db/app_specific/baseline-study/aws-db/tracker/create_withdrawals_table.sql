
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_withdrawals select_subject_withdrew_reason select_investigator_terminated lost_to_follow_up_no_yes no_longer_participating_no_yes notes

      CREATE FUNCTION log_ipa_withdrawal_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_withdrawal_history
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
                      ipa_withdrawal_id
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

      CREATE TABLE ipa_withdrawal_history (
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
          ipa_withdrawal_id integer
      );

      CREATE SEQUENCE ipa_withdrawal_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_withdrawal_history_id_seq OWNED BY ipa_withdrawal_history.id;

      CREATE TABLE ipa_withdrawals (
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
      CREATE SEQUENCE ipa_withdrawals_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_withdrawals_id_seq OWNED BY ipa_withdrawals.id;

      ALTER TABLE ONLY ipa_withdrawals ALTER COLUMN id SET DEFAULT nextval('ipa_withdrawals_id_seq'::regclass);
      ALTER TABLE ONLY ipa_withdrawal_history ALTER COLUMN id SET DEFAULT nextval('ipa_withdrawal_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_withdrawal_history
          ADD CONSTRAINT ipa_withdrawal_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_withdrawals
          ADD CONSTRAINT ipa_withdrawals_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_withdrawal_history_on_master_id ON ipa_withdrawal_history USING btree (master_id);


      CREATE INDEX index_ipa_withdrawal_history_on_ipa_withdrawal_id ON ipa_withdrawal_history USING btree (ipa_withdrawal_id);
      CREATE INDEX index_ipa_withdrawal_history_on_user_id ON ipa_withdrawal_history USING btree (user_id);

      CREATE INDEX index_ipa_withdrawals_on_master_id ON ipa_withdrawals USING btree (master_id);

      CREATE INDEX index_ipa_withdrawals_on_user_id ON ipa_withdrawals USING btree (user_id);

      CREATE TRIGGER ipa_withdrawal_history_insert AFTER INSERT ON ipa_withdrawals FOR EACH ROW EXECUTE PROCEDURE log_ipa_withdrawal_update();
      CREATE TRIGGER ipa_withdrawal_history_update AFTER UPDATE ON ipa_withdrawals FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_withdrawal_update();


      ALTER TABLE ONLY ipa_withdrawals
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_withdrawals
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_withdrawal_history
          ADD CONSTRAINT fk_ipa_withdrawal_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_withdrawal_history
          ADD CONSTRAINT fk_ipa_withdrawal_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_withdrawal_history
          ADD CONSTRAINT fk_ipa_withdrawal_history_ipa_withdrawals FOREIGN KEY (ipa_withdrawal_id) REFERENCES ipa_withdrawals(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
