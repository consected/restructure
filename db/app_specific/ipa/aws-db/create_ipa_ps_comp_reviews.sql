set search_path=ipa_ops, ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_ps_comp_reviews how_long_notes clinical_care_or_research_notes two_assessments_notes risks_notes study_drugs_notes compensation_notes location_notes notes

      CREATE FUNCTION log_ipa_ps_comp_review_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_ps_comp_review_history
                  (
                      master_id,
                      how_long_notes,
                      clinical_care_or_research_notes,
                      two_assessments_notes,
                      risks_notes,
                      study_drugs_notes,
                      compensation_notes,
                      location_notes,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_ps_comp_review_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.how_long_notes,
                      NEW.clinical_care_or_research_notes,
                      NEW.two_assessments_notes,
                      NEW.risks_notes,
                      NEW.study_drugs_notes,
                      NEW.compensation_notes,
                      NEW.location_notes,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_ps_comp_review_history (
          id integer NOT NULL,
          master_id integer,
          how_long_notes varchar,
          clinical_care_or_research_notes varchar,
          two_assessments_notes varchar,
          risks_notes varchar,
          study_drugs_notes varchar,
          compensation_notes varchar,
          location_notes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_ps_comp_review_id integer
      );

      CREATE SEQUENCE ipa_ps_comp_review_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_comp_review_history_id_seq OWNED BY ipa_ps_comp_review_history.id;

      CREATE TABLE ipa_ps_comp_reviews (
          id integer NOT NULL,
          master_id integer,
          how_long_notes varchar,
          clinical_care_or_research_notes varchar,
          two_assessments_notes varchar,
          risks_notes varchar,
          study_drugs_notes varchar,
          compensation_notes varchar,
          location_notes varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_ps_comp_reviews_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_ps_comp_reviews_id_seq OWNED BY ipa_ps_comp_reviews.id;

      ALTER TABLE ONLY ipa_ps_comp_reviews ALTER COLUMN id SET DEFAULT nextval('ipa_ps_comp_reviews_id_seq'::regclass);
      ALTER TABLE ONLY ipa_ps_comp_review_history ALTER COLUMN id SET DEFAULT nextval('ipa_ps_comp_review_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_ps_comp_review_history
          ADD CONSTRAINT ipa_ps_comp_review_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_ps_comp_reviews
          ADD CONSTRAINT ipa_ps_comp_reviews_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_ps_comp_review_history_on_master_id ON ipa_ps_comp_review_history USING btree (master_id);


      CREATE INDEX index_ipa_ps_comp_review_history_on_ipa_ps_comp_review_id ON ipa_ps_comp_review_history USING btree (ipa_ps_comp_review_id);
      CREATE INDEX index_ipa_ps_comp_review_history_on_user_id ON ipa_ps_comp_review_history USING btree (user_id);

      CREATE INDEX index_ipa_ps_comp_reviews_on_master_id ON ipa_ps_comp_reviews USING btree (master_id);

      CREATE INDEX index_ipa_ps_comp_reviews_on_user_id ON ipa_ps_comp_reviews USING btree (user_id);

      CREATE TRIGGER ipa_ps_comp_review_history_insert AFTER INSERT ON ipa_ps_comp_reviews FOR EACH ROW EXECUTE PROCEDURE log_ipa_ps_comp_review_update();
      CREATE TRIGGER ipa_ps_comp_review_history_update AFTER UPDATE ON ipa_ps_comp_reviews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_ps_comp_review_update();


      ALTER TABLE ONLY ipa_ps_comp_reviews
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_ps_comp_reviews
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_ps_comp_review_history
          ADD CONSTRAINT fk_ipa_ps_comp_review_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_ps_comp_review_history
          ADD CONSTRAINT fk_ipa_ps_comp_review_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_ps_comp_review_history
          ADD CONSTRAINT fk_ipa_ps_comp_review_history_ipa_ps_comp_reviews FOREIGN KEY (ipa_ps_comp_review_id) REFERENCES ipa_ps_comp_reviews(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
