SET search_path = femfl, ml_app;

BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create femfl_subjects first_name last_name middle_name nick_name birth_date

CREATE FUNCTION log_femfl_subject_update ()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  INSERT INTO femfl_subject_history (
    master_id,
    first_name,
    last_name,
    middle_name,
    nick_name,
    birth_date,
    rank,
    source,
    user_id,
    created_at,
    updated_at,
    femfl_subject_id)
  SELECT
    NEW.master_id,
    NEW.first_name,
    NEW.last_name,
    NEW.middle_name,
    NEW.nick_name,
    NEW.birth_date,
    NEW.rank,
    NEW.source,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;

CREATE TABLE femfl_subject_history (
  id integer NOT NULL,
  master_id integer,
  first_name varchar,
  last_name varchar,
  middle_name varchar,
  nick_name varchar,
  birth_date date,
  rank integer,
  source varchar,
  user_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL,
  femfl_subject_id integer
);

CREATE SEQUENCE femfl_subject_history_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE femfl_subject_history_id_seq OWNED BY femfl_subject_history.id;

CREATE TABLE femfl_subjects (
  id integer NOT NULL,
  master_id integer,
  first_name varchar,
  last_name varchar,
  middle_name varchar,
  nick_name varchar,
  birth_date date,
  rank integer,
  source varchar,
  user_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL
);

CREATE SEQUENCE femfl_subjects_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE femfl_subjects_id_seq OWNED BY femfl_subjects.id;

ALTER TABLE ONLY femfl_subjects
  ALTER COLUMN id SET DEFAULT nextval('femfl_subjects_id_seq'::regclass);

ALTER TABLE ONLY femfl_subject_history
  ALTER COLUMN id SET DEFAULT nextval('femfl_subject_history_id_seq'::regclass);

ALTER TABLE ONLY femfl_subject_history
  ADD CONSTRAINT femfl_subject_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY femfl_subjects
  ADD CONSTRAINT femfl_subjects_pkey PRIMARY KEY (id);

CREATE INDEX index_femfl_subject_history_on_master_id ON femfl_subject_history USING btree (master_id);

CREATE INDEX index_femfl_subject_history_on_femfl_subject_id ON femfl_subject_history USING btree (femfl_subject_id);

CREATE INDEX index_femfl_subject_history_on_user_id ON femfl_subject_history USING btree (user_id);

CREATE INDEX index_femfl_subjects_on_master_id ON femfl_subjects USING btree (master_id);

CREATE INDEX index_femfl_subjects_on_user_id ON femfl_subjects USING btree (user_id);

CREATE TRIGGER femfl_subject_history_insert
  AFTER INSERT ON femfl_subjects
  FOR EACH ROW
  EXECUTE PROCEDURE log_femfl_subject_update ();

CREATE TRIGGER femfl_subject_history_update
  AFTER UPDATE ON femfl_subjects
  FOR EACH ROW
  WHEN ((OLD.* IS DISTINCT FROM NEW.*))
  EXECUTE PROCEDURE log_femfl_subject_update ();

ALTER TABLE ONLY femfl_subjects
  ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY femfl_subjects
  ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters (id);

-- ALTER TABLE ONLY femfl_subjects
--     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE ONLY femfl_subject_history
  ADD CONSTRAINT fk_femfl_subject_history_users FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY femfl_subject_history
  ADD CONSTRAINT fk_femfl_subject_history_masters FOREIGN KEY (master_id) REFERENCES masters (id);

-- ALTER TABLE ONLY femfl_subject_history
--     ADD CONSTRAINT fk_femfl_subject_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE ONLY femfl_subject_history
  ADD CONSTRAINT fk_femfl_subject_history_femfl_subjects FOREIGN KEY (femfl_subject_id) REFERENCES femfl_subjects (id);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

