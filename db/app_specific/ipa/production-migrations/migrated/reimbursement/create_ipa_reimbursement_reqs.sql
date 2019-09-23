set search_path=ipa_ops, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_reimbursement_reqs participant_requested_yes_no submission_date additional_notes

      CREATE FUNCTION log_ipa_reimbursement_req_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_reimbursement_req_history
                  (
                      master_id,
                      participant_requested_yes_no,
                      submission_date,
                      additional_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_reimbursement_req_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.participant_requested_yes_no,
                      NEW.submission_date,
                      NEW.additional_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_reimbursement_req_history (
          id integer NOT NULL,
          master_id integer,
          participant_requested_yes_no varchar,
          submission_date date,
          additional_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_reimbursement_req_id integer
      );

      CREATE SEQUENCE ipa_reimbursement_req_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_reimbursement_req_history_id_seq OWNED BY ipa_reimbursement_req_history.id;

      CREATE TABLE ipa_reimbursement_reqs (
          id integer NOT NULL,
          master_id integer,
          participant_requested_yes_no varchar,
          submission_date date,
          additional_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_reimbursement_reqs_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_reimbursement_reqs_id_seq OWNED BY ipa_reimbursement_reqs.id;

      ALTER TABLE ONLY ipa_reimbursement_reqs ALTER COLUMN id SET DEFAULT nextval('ipa_reimbursement_reqs_id_seq'::regclass);
      ALTER TABLE ONLY ipa_reimbursement_req_history ALTER COLUMN id SET DEFAULT nextval('ipa_reimbursement_req_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_reimbursement_req_history
          ADD CONSTRAINT ipa_reimbursement_req_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_reimbursement_reqs
          ADD CONSTRAINT ipa_reimbursement_reqs_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_reimbursement_req_history_on_master_id ON ipa_reimbursement_req_history USING btree (master_id);


      CREATE INDEX index_ipa_reimbursement_req_history_on_ipa_reimbursement_req_id ON ipa_reimbursement_req_history USING btree (ipa_reimbursement_req_id);
      CREATE INDEX index_ipa_reimbursement_req_history_on_user_id ON ipa_reimbursement_req_history USING btree (user_id);

      CREATE INDEX index_ipa_reimbursement_reqs_on_master_id ON ipa_reimbursement_reqs USING btree (master_id);

      CREATE INDEX index_ipa_reimbursement_reqs_on_user_id ON ipa_reimbursement_reqs USING btree (user_id);

      CREATE TRIGGER ipa_reimbursement_req_history_insert AFTER INSERT ON ipa_reimbursement_reqs FOR EACH ROW EXECUTE PROCEDURE log_ipa_reimbursement_req_update();
      CREATE TRIGGER ipa_reimbursement_req_history_update AFTER UPDATE ON ipa_reimbursement_reqs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_reimbursement_req_update();


      ALTER TABLE ONLY ipa_reimbursement_reqs
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_reimbursement_reqs
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_reimbursement_req_history
          ADD CONSTRAINT fk_ipa_reimbursement_req_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_reimbursement_req_history
          ADD CONSTRAINT fk_ipa_reimbursement_req_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_reimbursement_req_history
          ADD CONSTRAINT fk_ipa_reimbursement_req_history_ipa_reimbursement_reqs FOREIGN KEY (ipa_reimbursement_req_id) REFERENCES ipa_reimbursement_reqs(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
