SET search_path = data_requests, ml_app;

BEGIN;

-- Command line:
-- table_generators/generate.sh create external_identifiers_table 

CREATE FUNCTION log_data_request_assignment_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO data_request_assignment_history
            (
                master_id,
                data_request_id,
                
                user_id,
                admin_id,
                created_at,
                updated_at,
                data_request_assignment_table_id
                )
            SELECT
                NEW.master_id,
                NEW.data_request_id,
                
                NEW.user_id,
                NEW.admin_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;
CREATE TABLE data_request_assignment_history (
    id integer NOT NULL,
    master_id integer,
    data_request_id bigint,
    
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_request_assignment_table_id integer
);

CREATE SEQUENCE data_request_assignment_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE data_request_assignment_history_id_seq OWNED BY data_request_assignment_history.id;

CREATE TABLE data_request_assignments (
    id integer NOT NULL,
    master_id integer,
    data_request_id bigint,
    
    user_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE data_request_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE data_request_assignments_id_seq OWNED BY data_request_assignments.id;

ALTER TABLE ONLY data_request_assignments ALTER COLUMN id SET DEFAULT nextval('data_request_assignments_id_seq'::regclass);
ALTER TABLE ONLY data_request_assignment_history ALTER COLUMN id SET DEFAULT nextval('data_request_assignment_history_id_seq'::regclass);

ALTER TABLE ONLY data_request_assignment_history
    ADD CONSTRAINT data_request_assignment_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY data_request_assignments
    ADD CONSTRAINT data_request_assignments_pkey PRIMARY KEY (id);

CREATE INDEX index_data_request_assignment_history_on_master_id ON data_request_assignment_history USING btree (master_id);
CREATE INDEX index_data_request_assignment_history_on_data_request_assignment_table_id ON data_request_assignment_history USING btree (data_request_assignment_table_id);
CREATE INDEX index_data_request_assignment_history_on_user_id ON data_request_assignment_history USING btree (user_id);
CREATE INDEX index_data_request_assignment_history_on_admin_id ON data_request_assignment_history USING btree (admin_id);

CREATE INDEX index_data_request_assignments_on_master_id ON data_request_assignments USING btree (master_id);
CREATE INDEX index_data_request_assignments_on_user_id ON data_request_assignments USING btree (user_id);
CREATE INDEX index_data_request_assignments_on_admin_id ON data_request_assignments USING btree (admin_id);

CREATE TRIGGER data_request_assignment_history_insert AFTER INSERT ON data_request_assignments FOR EACH ROW EXECUTE PROCEDURE log_data_request_assignment_update();
CREATE TRIGGER data_request_assignment_history_update AFTER UPDATE ON data_request_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_data_request_assignment_update();


ALTER TABLE ONLY data_request_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY data_request_assignments
    ADD CONSTRAINT fk_rails_1a7e2b01e0admin FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY data_request_assignments
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);

-- ALTER TABLE ONLY data_request_assignments
--     ADD CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);


ALTER TABLE ONLY data_request_assignment_history
    ADD CONSTRAINT fk_data_request_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY data_request_assignment_history
    ADD CONSTRAINT fk_data_request_assignment_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY data_request_assignment_history
    ADD CONSTRAINT fk_data_request_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE ONLY data_request_assignment_history
    ADD CONSTRAINT fk_data_request_assignment_history_data_request_assignments FOREIGN KEY (data_request_assignment_table_id) REFERENCES data_request_assignments(id);

-- ALTER TABLE ONLY data_request_assignment_history
--     ADD CONSTRAINT fk_data_request_assignment_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);


GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA data_requests TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

COMMIT;
