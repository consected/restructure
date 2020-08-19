SET search_path = ml_app;

BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

CREATE OR REPLACE FUNCTION log_pitt_bhi_assignment_update ()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  INSERT INTO pitt_bhi_assignment_history (
    master_id,
    pitt_bhi_id,
    user_id,
    admin_id,
    created_at,
    updated_at,
    pitt_bhi_assignment_table_id)
  SELECT
    NEW.master_id,
    NEW.pitt_bhi_id,
    NEW.user_id,
    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.id;
  RETURN NEW;
END;
$$;

CREATE TABLE pitt_bhi_assignment_history (
  id integer NOT NULL,
  master_id integer,
  pitt_bhi_id bigint,
  user_id integer,
  admin_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL,
  pitt_bhi_assignment_table_id integer
);

CREATE SEQUENCE pitt_bhi_assignment_history_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE pitt_bhi_assignment_history_id_seq OWNED BY pitt_bhi_assignment_history.id;

CREATE TABLE pitt_bhi_assignments (
  id integer NOT NULL,
  master_id integer,
  pitt_bhi_id bigint,
  user_id integer,
  admin_id integer,
  created_at timestamp WITHOUT time zone NOT NULL,
  updated_at timestamp WITHOUT time zone NOT NULL
);

CREATE SEQUENCE pitt_bhi_assignments_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER SEQUENCE pitt_bhi_assignments_id_seq OWNED BY pitt_bhi_assignments.id;

ALTER TABLE ONLY pitt_bhi_assignments
  ALTER COLUMN id SET DEFAULT nextval('pitt_bhi_assignments_id_seq'::regclass);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ALTER COLUMN id SET DEFAULT nextval('pitt_bhi_assignment_history_id_seq'::regclass);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ADD CONSTRAINT pitt_bhi_assignment_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY pitt_bhi_assignments
  ADD CONSTRAINT pitt_bhi_assignments_pkey PRIMARY KEY (id);

CREATE INDEX index_pitt_bhi_assignment_history_on_master_id ON pitt_bhi_assignment_history USING btree (master_id);

CREATE INDEX index_pitt_bhi_assignment_history_on_pitt_bhi_assignment_table_id ON pitt_bhi_assignment_history USING btree (pitt_bhi_assignment_table_id);

CREATE INDEX index_pitt_bhi_assignment_history_on_user_id ON pitt_bhi_assignment_history USING btree (user_id);

CREATE INDEX index_pitt_bhi_assignment_history_on_admin_id ON pitt_bhi_assignment_history USING btree (admin_id);

CREATE INDEX index_pitt_bhi_assignments_on_master_id ON pitt_bhi_assignments USING btree (master_id);

CREATE INDEX index_pitt_bhi_assignments_on_user_id ON pitt_bhi_assignments USING btree (user_id);

CREATE INDEX index_pitt_bhi_assignments_on_admin_id ON pitt_bhi_assignments USING btree (admin_id);

CREATE TRIGGER pitt_bhi_assignment_history_insert
  AFTER INSERT ON pitt_bhi_assignments
  FOR EACH ROW
  EXECUTE PROCEDURE log_pitt_bhi_assignment_update ();

CREATE TRIGGER pitt_bhi_assignment_history_update
  AFTER UPDATE ON pitt_bhi_assignments
  FOR EACH ROW
  WHEN ((OLD.* IS DISTINCT FROM NEW.*))
  EXECUTE PROCEDURE log_pitt_bhi_assignment_update ();

ALTER TABLE ONLY pitt_bhi_assignments
  ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY pitt_bhi_assignments
  ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins (id);

ALTER TABLE ONLY pitt_bhi_assignments
  ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters (id);

-- ALTER TABLE ONLY pitt_bhi_assignments
--     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ADD CONSTRAINT fk_pitt_bhi_assignment_history_users FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ADD CONSTRAINT fk_pitt_bhi_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins (id);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ADD CONSTRAINT fk_pitt_bhi_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters (id);

ALTER TABLE ONLY pitt_bhi_assignment_history
  ADD CONSTRAINT fk_pitt_bhi_assignment_history_pitt_bhi_assignments FOREIGN KEY (pitt_bhi_assignment_table_id) REFERENCES pitt_bhi_assignments (id);

-- ALTER TABLE ONLY pitt_bhi_assignment_history
--     ADD CONSTRAINT fk_pitt_bhi_assignment_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

