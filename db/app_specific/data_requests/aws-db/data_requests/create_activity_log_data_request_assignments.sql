SET
    search_path = data_requests,
    ml_app;

BEGIN
;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_data_request_assignments data_request_assignment follow_up_date follow_up_time notes
CREATE TABLE activity_log_data_request_assignment_history (
    id INTEGER NOT NULL,
    master_id INTEGER,
    data_request_assignment_id INTEGER,
    follow_up_date DATE,
    follow_up_time TIME,
    next_step VARCHAR,
    status VARCHAR,
    notes VARCHAR,
    extra_log_type VARCHAR,
    user_id INTEGER,
    created_by_user_id INTEGER,
    created_at TIMESTAMP without TIME ZONE NOT NULL,
    updated_at TIMESTAMP without TIME ZONE NOT NULL,
    activity_log_data_request_assignment_id INTEGER
);

CREATE TABLE activity_log_data_request_assignments (
    id INTEGER NOT NULL,
    master_id INTEGER,
    data_request_assignment_id INTEGER,
    follow_up_date DATE,
    follow_up_time TIME,
    next_step VARCHAR,
    status VARCHAR,
    notes VARCHAR,
    extra_log_type VARCHAR,
    user_id INTEGER,
    created_by_user_id INTEGER,
    created_at TIMESTAMP without TIME ZONE NOT NULL,
    updated_at TIMESTAMP without TIME ZONE NOT NULL
);

CREATE
OR REPLACE FUNCTION log_activity_log_data_request_assignment_update() RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    INSERT INTO
        activity_log_data_request_assignment_history (
            master_id,
            data_request_assignment_id,
            follow_up_date,
            follow_up_time,
            next_step,
            status,
            notes,
            extra_log_type,
            user_id,
            created_by_user_id,
            created_at,
            updated_at,
            activity_log_data_request_assignment_id
        )
    SELECT
        NEW .master_id,
        NEW .data_request_assignment_id,
        NEW .follow_up_date,
        NEW .follow_up_time,
        NEW .next_step,
        NEW .status,
        NEW .notes,
        NEW .extra_log_type,
        NEW .user_id,
        NEW .created_by_user_id,
        NEW .created_at,
        NEW .updated_at,
        NEW .id;

RETURN NEW;

END;

$$;

CREATE SEQUENCE activity_log_data_request_assignment_history_id_seq
START WITH
    1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE activity_log_data_request_assignment_history_id_seq OWNED BY activity_log_data_request_assignment_history.id;

CREATE SEQUENCE activity_log_data_request_assignments_id_seq
START WITH
    1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE activity_log_data_request_assignments_id_seq OWNED BY activity_log_data_request_assignments.id;

ALTER TABLE
    ONLY activity_log_data_request_assignments
ALTER COLUMN
    id
SET
    DEFAULT NEXTVAL(
        'activity_log_data_request_assignments_id_seq' :: regclass
    );

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ALTER COLUMN
    id
SET
    DEFAULT NEXTVAL(
        'activity_log_data_request_assignment_history_id_seq' :: regclass
    );

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT activity_log_data_request_assignment_history_pkey PRIMARY KEY (id);

ALTER TABLE
    ONLY activity_log_data_request_assignments
ADD
    CONSTRAINT activity_log_data_request_assignments_pkey PRIMARY KEY (id);

CREATE INDEX index_al_data_request_assignment_history_on_master_id ON activity_log_data_request_assignment_history USING btree (master_id);

CREATE INDEX index_al_data_request_assignment_history_on_data_request_assignment_id ON activity_log_data_request_assignment_history USING btree (data_request_assignment_id);

CREATE INDEX index_al_data_request_assignment_history_on_activity_log_data_request_assignment_id ON activity_log_data_request_assignment_history USING btree (activity_log_data_request_assignment_id);

CREATE INDEX index_al_data_request_assignment_history_on_user_id ON activity_log_data_request_assignment_history USING btree (user_id);

CREATE INDEX index_activity_log_data_request_assignments_on_master_id ON activity_log_data_request_assignments USING btree (master_id);

CREATE INDEX index_activity_log_data_request_assignments_on_data_request_assignment_id ON activity_log_data_request_assignments USING btree (data_request_assignment_id);

CREATE INDEX index_activity_log_data_request_assignments_on_user_id ON activity_log_data_request_assignments USING btree (user_id);

CREATE TRIGGER activity_log_data_request_assignment_history_insert AFTER
INSERT
    ON activity_log_data_request_assignments FOR EACH ROW EXECUTE PROCEDURE log_activity_log_data_request_assignment_update();

CREATE TRIGGER activity_log_data_request_assignment_history_update AFTER
UPDATE
    ON activity_log_data_request_assignments FOR EACH ROW
    WHEN (
        (
            OLD.* IS DISTINCT
            FROM
                NEW.*
        )
    ) EXECUTE PROCEDURE log_activity_log_data_request_assignment_update();

ALTER TABLE
    ONLY activity_log_data_request_assignments
ADD
    CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE
    ONLY activity_log_data_request_assignments
ADD
    CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE
    ONLY activity_log_data_request_assignments
ADD
    CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (data_request_assignment_id) REFERENCES data_request_assignments(id);

ALTER TABLE
    ONLY activity_log_data_request_assignments
ADD
    CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT fk_activity_log_data_request_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT fk_activity_log_data_request_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT fk_activity_log_data_request_assignment_history_data_request_assignment_id FOREIGN KEY (data_request_assignment_id) REFERENCES data_request_assignments(id);

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT fk_activity_log_data_request_assignment_history_activity_log_data_request_assignments FOREIGN KEY (activity_log_data_request_assignment_id) REFERENCES activity_log_data_request_assignments(id);

ALTER TABLE
    ONLY activity_log_data_request_assignment_history
ADD
    CONSTRAINT fk_activity_log_data_request_assignment_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);

GRANT
SELECT
,
INSERT
,
UPDATE
,
DELETE
    ON ALL TABLES IN SCHEMA data_requests TO fphs;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

GRANT
SELECT
    ON ALL SEQUENCES IN SCHEMA data_requests TO fphs;

COMMIT;