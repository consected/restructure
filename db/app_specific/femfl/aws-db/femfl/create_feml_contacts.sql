SET search_path = femfl, ml_app;

BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create feml_contacts rec_type data rank

CREATE FUNCTION log_feml_contact_update ()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  INSERT INTO femfl_contact_history (
    master_id,
    rec_type,
    data,
    rank,
    source,
    user_id,
    created_at,
    updated_at,
    femfl_contact_id)
  SELECT
    NEW.master_id,
    NEW.rec_type,
    NEW.data,
    NEW.rank,
    NEW.source,
    NEW.user_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;

CREATE TABLE feml_contact_history (
  id integer NOT NULL,
  master_id integer,
  rec_type varchar,
  data varchar,
  rank integer,
  source varchar,
  user_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL,
  feml_contact_id integer
);

CREATE SEQUENCE feml_contact_history_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE feml_contact_history_id_seq OWNED BY feml_contact_history.id;

CREATE TABLE feml_contacts (
  id integer NOT NULL,
  master_id integer,
  rec_type varchar,
  data varchar,
  rank integer,
  source varchar,
  user_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL
);

CREATE SEQUENCE feml_contacts_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE feml_contacts_id_seq OWNED BY feml_contacts.id;

ALTER TABLE ONLY feml_contacts
  ALTER COLUMN id SET DEFAULT nextval('feml_contacts_id_seq'::regclass);

ALTER TABLE ONLY feml_contact_history
  ALTER COLUMN id SET DEFAULT nextval('feml_contact_history_id_seq'::regclass);

ALTER TABLE ONLY feml_contact_history
  ADD CONSTRAINT feml_contact_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY feml_contacts
  ADD CONSTRAINT feml_contacts_pkey PRIMARY KEY (id);

CREATE INDEX index_feml_contact_history_on_master_id ON feml_contact_history USING btree (master_id);

CREATE INDEX index_feml_contact_history_on_feml_contact_id ON feml_contact_history USING btree (feml_contact_id);

CREATE INDEX index_feml_contact_history_on_user_id ON feml_contact_history USING btree (user_id);

CREATE INDEX index_feml_contacts_on_master_id ON feml_contacts USING btree (master_id);

CREATE INDEX index_feml_contacts_on_user_id ON feml_contacts USING btree (user_id);

CREATE TRIGGER feml_contact_history_insert
  AFTER INSERT ON feml_contacts
  FOR EACH ROW
  EXECUTE PROCEDURE log_feml_contact_update ();

CREATE TRIGGER feml_contact_history_update
  AFTER UPDATE ON feml_contacts
  FOR EACH ROW
  WHEN ((OLD.* IS DISTINCT FROM NEW.*))
  EXECUTE PROCEDURE log_feml_contact_update ();

ALTER TABLE ONLY feml_contacts
  ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY feml_contacts
  ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters (id);

-- ALTER TABLE ONLY feml_contacts
--     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE ONLY feml_contact_history
  ADD CONSTRAINT fk_feml_contact_history_users FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY feml_contact_history
  ADD CONSTRAINT fk_feml_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters (id);

-- ALTER TABLE ONLY feml_contact_history
--     ADD CONSTRAINT fk_feml_contact_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE ONLY feml_contact_history
  ADD CONSTRAINT fk_feml_contact_history_feml_contacts FOREIGN KEY (feml_contact_id) REFERENCES feml_contacts (id);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

