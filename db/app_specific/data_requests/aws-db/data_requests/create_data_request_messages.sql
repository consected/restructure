SET
    search_path = data_requests,
    ml_app;

BEGIN
;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create data_request_messages message_notes created_by_user_id
CREATE FUNCTION log_data_request_message_update() RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    INSERT INTO
        data_request_message_history (
            master_id,
            message_notes,
            created_by_user_id,
            user_id,
            created_at,
            updated_at,
            data_request_message_id
        )
    SELECT
        NEW .master_id,
        NEW .message_notes,
        NEW .created_by_user_id,
        NEW .user_id,
        NEW .created_at,
        NEW .updated_at,
        NEW .id;

RETURN NEW;

END;

$$;

CREATE TABLE data_request_message_history (
    id INTEGER NOT NULL,
    master_id INTEGER,
    message_notes VARCHAR,
    created_by_user_id INTEGER,
    user_id INTEGER,
    created_at TIMESTAMP without TIME ZONE NOT NULL,
    updated_at TIMESTAMP without TIME ZONE NOT NULL,
    data_request_message_id INTEGER
);

CREATE SEQUENCE data_request_message_history_id_seq
START WITH
    1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE data_request_message_history_id_seq OWNED BY data_request_message_history.id;

CREATE TABLE data_request_messages (
    id INTEGER NOT NULL,
    master_id INTEGER,
    message_notes VARCHAR,
    created_by_user_id INTEGER,
    user_id INTEGER,
    created_at TIMESTAMP without TIME ZONE NOT NULL,
    updated_at TIMESTAMP without TIME ZONE NOT NULL
);

CREATE SEQUENCE data_request_messages_id_seq
START WITH
    1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE data_request_messages_id_seq OWNED BY data_request_messages.id;

ALTER TABLE
    ONLY data_request_messages
ALTER COLUMN
    id
SET
    DEFAULT NEXTVAL(
        'data_request_messages_id_seq' :: regclass
    );

ALTER TABLE
    ONLY data_request_message_history
ALTER COLUMN
    id
SET
    DEFAULT NEXTVAL(
        'data_request_message_history_id_seq' :: regclass
    );

ALTER TABLE
    ONLY data_request_message_history
ADD
    CONSTRAINT data_request_message_history_pkey PRIMARY KEY (id);

ALTER TABLE
    ONLY data_request_messages
ADD
    CONSTRAINT data_request_messages_pkey PRIMARY KEY (id);

CREATE INDEX index_data_request_message_history_on_master_id ON data_request_message_history USING btree (master_id);

CREATE INDEX index_data_request_message_history_on_data_request_message_id ON data_request_message_history USING btree (data_request_message_id);

CREATE INDEX index_data_request_message_history_on_user_id ON data_request_message_history USING btree (user_id);

CREATE INDEX index_data_request_messages_on_master_id ON data_request_messages USING btree (master_id);

CREATE INDEX index_data_request_messages_on_user_id ON data_request_messages USING btree (user_id);

CREATE TRIGGER data_request_message_history_insert AFTER
INSERT
    ON data_request_messages FOR EACH ROW EXECUTE PROCEDURE log_data_request_message_update();

CREATE TRIGGER data_request_message_history_update AFTER
UPDATE
    ON data_request_messages FOR EACH ROW
    WHEN (
        (
            OLD.* IS DISTINCT
            FROM
                NEW.*
        )
    ) EXECUTE PROCEDURE log_data_request_message_update();

ALTER TABLE
    ONLY data_request_messages
ADD
    CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE
    ONLY data_request_messages
ADD
    CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE
    ONLY data_request_messages
ADD
    CONSTRAINT fk_rails_982635401e0 FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE
    ONLY data_request_message_history
ADD
    CONSTRAINT fk_data_request_message_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE
    ONLY data_request_message_history
ADD
    CONSTRAINT fk_data_request_message_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

ALTER TABLE
    ONLY data_request_message_history
ADD
    CONSTRAINT fk_data_request_message_history_cb_users FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE
    ONLY data_request_message_history
ADD
    CONSTRAINT fk_data_request_message_history_data_request_messages FOREIGN KEY (data_request_message_id) REFERENCES data_request_messages(id);

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