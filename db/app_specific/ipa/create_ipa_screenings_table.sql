
      BEGIN;

      CREATE FUNCTION log_ipa_screening_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_screening_history
                  (
                      master_id,
                      screening_date,
                      eligible_for_study_blank_yes_no,
                      select_reason_if_not_eligible,
                      notes,
                      select_status,
                      select_subject_withdrew_reason,
                      select_investigator_terminated,
                      lost_to_follow_up_no_yes,
                      select_no_longer_participating,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.screening_date,
                      NEW.eligible_for_study_blank_yes_no,
                      NEW.select_reason_if_not_eligible,
                      NEW.notes,
                      NEW.select_status,
                      NEW.select_subject_withdrew_reason,
                      NEW.select_investigator_terminated,
                      NEW.lost_to_follow_up_no_yes,
                      NEW.select_no_longer_participating,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_screening_history (
          id integer NOT NULL,
          master_id integer,
          screening_date date,
          eligible_for_study_blank_yes_no varchar,
          select_reason_if_not_eligible varchar,
          notes varchar,
          select_status varchar,
          select_subject_withdrew_reason varchar,
          select_investigator_terminated varchar,
          lost_to_follow_up_no_yes varchar,
          select_no_longer_participating varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_screening_id integer
      );

      CREATE SEQUENCE ipa_screening_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_screening_history_id_seq OWNED BY ipa_screening_history.id;

      CREATE TABLE ipa_screenings (
          id integer NOT NULL,
          master_id integer,
          screening_date date,
          eligible_for_study_blank_yes_no varchar,
          select_reason_if_not_eligible varchar,
          notes varchar,
          select_status varchar,
          select_subject_withdrew_reason varchar,
          select_investigator_terminated varchar,
          lost_to_follow_up_no_yes varchar,
          select_no_longer_participating varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_screenings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_screenings_id_seq OWNED BY ipa_screenings.id;

      ALTER TABLE ONLY ipa_screenings ALTER COLUMN id SET DEFAULT nextval('ipa_screenings_id_seq'::regclass);
      ALTER TABLE ONLY ipa_screening_history ALTER COLUMN id SET DEFAULT nextval('ipa_screening_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_screening_history
          ADD CONSTRAINT ipa_screening_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_screenings
          ADD CONSTRAINT ipa_screenings_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_screening_history_on_master_id ON ipa_screening_history USING btree (master_id);


      CREATE INDEX index_ipa_screening_history_on_ipa_screening_id ON ipa_screening_history USING btree (ipa_screening_id);
      CREATE INDEX index_ipa_screening_history_on_user_id ON ipa_screening_history USING btree (user_id);

      CREATE INDEX index_ipa_screenings_on_master_id ON ipa_screenings USING btree (master_id);

      CREATE INDEX index_ipa_screenings_on_user_id ON ipa_screenings USING btree (user_id);

      CREATE TRIGGER ipa_screening_history_insert AFTER INSERT ON ipa_screenings FOR EACH ROW EXECUTE PROCEDURE log_ipa_screening_update();
      CREATE TRIGGER ipa_screening_history_update AFTER UPDATE ON ipa_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_screening_update();


      ALTER TABLE ONLY ipa_screenings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_screenings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_screening_history
          ADD CONSTRAINT fk_ipa_screening_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_screening_history
          ADD CONSTRAINT fk_ipa_screening_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_screening_history
          ADD CONSTRAINT fk_ipa_screening_history_ipa_screenings FOREIGN KEY (ipa_screening_id) REFERENCES ipa_screenings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
