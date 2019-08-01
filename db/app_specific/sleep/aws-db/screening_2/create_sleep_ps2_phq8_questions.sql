set search_path=sleep, ml_app;

BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create sleep_ps2_phq8_questions little_interest feeling_down trouble_sleeping feeling_tired poor_appetite feeling_bad trouble_concentrating acting_slowly_or_restlessly

CREATE FUNCTION log_sleep_ps2_phq8_question_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sleep_ps2_phq8_question_history
            (
                master_id,
                little_interest,
                feeling_down,
                initial_score,
                trouble_sleeping,
                feeling_tired,
                poor_appetite,
                feeling_bad,
                trouble_concentrating,
                acting_slowly_or_restlessly,
                total_score,
                user_id,
                created_at,
                updated_at,
                sleep_ps2_phq8_question_id
                )
            SELECT
                NEW.master_id,
                NEW.little_interest,
                NEW.feeling_down,
                NEW.initial_score,
                NEW.trouble_sleeping,
                NEW.feeling_tired,
                NEW.poor_appetite,
                NEW.feeling_bad,
                NEW.trouble_concentrating,
                NEW.acting_slowly_or_restlessly,
                NEW.total_score,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE sleep_ps2_phq8_question_history (
    id integer NOT NULL,
    master_id integer,
    little_interest integer,
    feeling_down integer,
    initial_score integer,
    trouble_sleeping integer,
    feeling_tired integer,
    poor_appetite integer,
    feeling_bad integer,
    trouble_concentrating integer,
    acting_slowly_or_restlessly integer,
    total_score integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sleep_ps2_phq8_question_id integer
);

CREATE SEQUENCE sleep_ps2_phq8_question_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE sleep_ps2_phq8_question_history_id_seq OWNED BY sleep_ps2_phq8_question_history.id;

CREATE TABLE sleep_ps2_phq8_questions (
    id integer NOT NULL,
    master_id integer,
    little_interest integer,
    feeling_down integer,
    initial_score integer,
    trouble_sleeping integer,
    feeling_tired integer,
    poor_appetite integer,
    feeling_bad integer,
    trouble_concentrating integer,
    acting_slowly_or_restlessly integer,
    total_score integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE sleep_ps2_phq8_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE sleep_ps2_phq8_questions_id_seq OWNED BY sleep_ps2_phq8_questions.id;

ALTER TABLE ONLY sleep_ps2_phq8_questions ALTER COLUMN id SET DEFAULT nextval('sleep_ps2_phq8_questions_id_seq'::regclass);
ALTER TABLE ONLY sleep_ps2_phq8_question_history ALTER COLUMN id SET DEFAULT nextval('sleep_ps2_phq8_question_history_id_seq'::regclass);

ALTER TABLE ONLY sleep_ps2_phq8_question_history
    ADD CONSTRAINT sleep_ps2_phq8_question_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sleep_ps2_phq8_questions
    ADD CONSTRAINT sleep_ps2_phq8_questions_pkey PRIMARY KEY (id);

CREATE INDEX index_sleep_ps2_phq8_question_history_on_master_id ON sleep_ps2_phq8_question_history USING btree (master_id);


CREATE INDEX index_sleep_ps2_phq8_question_history_on_sleep_ps2_phq8_question_id ON sleep_ps2_phq8_question_history USING btree (sleep_ps2_phq8_question_id);
CREATE INDEX index_sleep_ps2_phq8_question_history_on_user_id ON sleep_ps2_phq8_question_history USING btree (user_id);

CREATE INDEX index_sleep_ps2_phq8_questions_on_master_id ON sleep_ps2_phq8_questions USING btree (master_id);

CREATE INDEX index_sleep_ps2_phq8_questions_on_user_id ON sleep_ps2_phq8_questions USING btree (user_id);

CREATE TRIGGER sleep_ps2_phq8_question_history_insert AFTER INSERT ON sleep_ps2_phq8_questions FOR EACH ROW EXECUTE PROCEDURE log_sleep_ps2_phq8_question_update();
CREATE TRIGGER sleep_ps2_phq8_question_history_update AFTER UPDATE ON sleep_ps2_phq8_questions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sleep_ps2_phq8_question_update();


ALTER TABLE ONLY sleep_ps2_phq8_questions
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY sleep_ps2_phq8_questions
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



ALTER TABLE ONLY sleep_ps2_phq8_question_history
    ADD CONSTRAINT fk_sleep_ps2_phq8_question_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY sleep_ps2_phq8_question_history
    ADD CONSTRAINT fk_sleep_ps2_phq8_question_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




ALTER TABLE ONLY sleep_ps2_phq8_question_history
    ADD CONSTRAINT fk_sleep_ps2_phq8_question_history_sleep_ps2_phq8_questions FOREIGN KEY (sleep_ps2_phq8_question_id) REFERENCES sleep_ps2_phq8_questions(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA sleep TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA sleep TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA sleep TO fphs;

COMMIT;
