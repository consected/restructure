
BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table

CREATE FUNCTION log_grit_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO grit_assignment_history
            (
                master_id,
                grit_id,
                user_id,
                admin_id,
                created_at,
                updated_at,
                grit_assignment_table_id
                )
            SELECT
                NEW.master_id,
                NEW.grit_id,
                NEW.user_id,
                NEW.admin_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;
CREATE TABLE grit_assignment_history (
    id integer NOT NULL,
    master_id integer,
    grit_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    grit_assignment_table_id integer
);

CREATE SEQUENCE grit_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE grit_assignment_history_id_seq OWNED BY grit_assignment_history.id;

CREATE TABLE grit_assignments (
    id integer NOT NULL,
    master_id integer,
    grit_id bigint,
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE grit_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE grit_assignments_id_seq OWNED BY grit_assignments.id;

ALTER TABLE ONLY grit_assignments ALTER COLUMN id SET DEFAULT nextval('grit_assignments_id_seq'::regclass);
ALTER TABLE ONLY grit_assignment_history ALTER COLUMN id SET DEFAULT nextval('grit_assignment_history_id_seq'::regclass);

ALTER TABLE ONLY grit_assignment_history ADD CONSTRAINT grit_assignment_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY grit_assignments ADD CONSTRAINT grit_assignments_pkey PRIMARY KEY (id);

CREATE INDEX index_grit_assignment_history_on_master_id ON grit_assignment_history USING btree (master_id);
CREATE INDEX index_grit_assignment_history_on_grit_assignment_table_id ON grit_assignment_history USING btree (grit_assignment_table_id);
CREATE INDEX index_grit_assignment_history_on_user_id ON grit_assignment_history USING btree (user_id);
CREATE INDEX index_grit_assignment_history_on_admin_id ON grit_assignment_history USING btree (admin_id);

CREATE INDEX index_grit_assignments_on_master_id ON grit_assignments USING btree (master_id);
CREATE INDEX index_grit_assignments_on_user_id ON grit_assignments USING btree (user_id);
CREATE INDEX index_grit_assignments_on_admin_id ON grit_assignments USING btree (admin_id);

CREATE TRIGGER grit_assignment_history_insert AFTER INSERT ON grit_assignments FOR EACH ROW EXECUTE PROCEDURE log_grit_assignment_update();
CREATE TRIGGER grit_assignment_history_update AFTER UPDATE ON grit_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_assignment_update();


ALTER TABLE ONLY grit_assignments ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY grit_assignments ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY grit_assignments ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


ALTER TABLE ONLY grit_assignment_history ADD CONSTRAINT fk_grit_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY grit_assignment_history ADD CONSTRAINT fk_grit_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY grit_assignment_history ADD CONSTRAINT fk_grit_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE ONLY grit_assignment_history ADD CONSTRAINT fk_grit_assignment_history_grit_assignments FOREIGN KEY (grit_assignment_table_id) REFERENCES grit_assignments(id);


GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;
