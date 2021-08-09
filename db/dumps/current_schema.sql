begin;
--
-- PostgreSQL database dump
--

-- Dumped from database version 10.10
-- Dumped by pg_dump version 10.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ref_data; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ref_data;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: datadic_choice_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_choice_history (
    id bigint NOT NULL,
    datadic_choice_id bigint,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_choice_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_choice_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_choice_history_id_seq OWNED BY ref_data.datadic_choice_history.id;


--
-- Name: datadic_choices; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_choices (
    id bigint NOT NULL,
    source_name character varying,
    source_type character varying,
    form_name character varying,
    field_name character varying,
    value character varying,
    label character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_choices_id_seq OWNED BY ref_data.datadic_choices.id;


--
-- Name: datadic_variable_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_variable_history (
    id bigint NOT NULL,
    datadic_variable_id bigint,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying
);


--
-- Name: COLUMN datadic_variable_history.study; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.study IS 'Study name';


--
-- Name: COLUMN datadic_variable_history.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.source_name IS 'Source of variable';


--
-- Name: COLUMN datadic_variable_history.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.source_type IS 'Source type';


--
-- Name: COLUMN datadic_variable_history.domain; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.domain IS 'Domain';


--
-- Name: COLUMN datadic_variable_history.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.form_name IS 'Form name (if the source was a type of form)';


--
-- Name: COLUMN datadic_variable_history.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.variable_name IS 'Variable name (as stored)';


--
-- Name: COLUMN datadic_variable_history.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.variable_type IS 'Variable type';


--
-- Name: COLUMN datadic_variable_history.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.presentation_type IS 'Data type for presentation purposes';


--
-- Name: COLUMN datadic_variable_history.label; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.label IS 'Primary label or title (if source was a form, the label presented for the field)';


--
-- Name: COLUMN datadic_variable_history.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.label_note IS 'Description (if source was a form, a note presented for the field)';


--
-- Name: COLUMN datadic_variable_history.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.annotation IS 'Annotations (if source was a form, annotations not presented to the user)';


--
-- Name: COLUMN datadic_variable_history.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_required IS 'Was required in source';


--
-- Name: COLUMN datadic_variable_history.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_type IS 'Source data type';


--
-- Name: COLUMN datadic_variable_history.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_min IS 'Minimum value';


--
-- Name: COLUMN datadic_variable_history.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.valid_max IS 'Maximum value';


--
-- Name: COLUMN datadic_variable_history.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_valid_choices IS 'List of valid choices for categorical variables';


--
-- Name: COLUMN datadic_variable_history.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_identifier IS 'Represents identifiable information';


--
-- Name: COLUMN datadic_variable_history.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.is_derived_var IS 'Is a derived variable';


--
-- Name: COLUMN datadic_variable_history.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_derived_from_id IS 'If a derived variable, ids of variables used to calculate it';


--
-- Name: COLUMN datadic_variable_history.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.doc_url IS 'URL to additional documentation';


--
-- Name: COLUMN datadic_variable_history.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.target_type IS 'Type of participant this variable relates to';


--
-- Name: COLUMN datadic_variable_history.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.owner_email IS 'Owner, especially for derived variables';


--
-- Name: COLUMN datadic_variable_history.classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.classification IS 'Category of sensitivity from a privacy perspective';


--
-- Name: COLUMN datadic_variable_history.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.other_classification IS 'Additional information regarding classification';


--
-- Name: COLUMN datadic_variable_history.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.multi_timepoints IS 'Timepoints this data is collected (in longitudinal studies)';


--
-- Name: COLUMN datadic_variable_history.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.equivalent_to_id IS 'Primary variable id this is equivalent to';


--
-- Name: COLUMN datadic_variable_history.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.storage_type IS 'Type of storage for dataset';


--
-- Name: COLUMN datadic_variable_history.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.db_or_fs IS 'Database or Filesystem name';


--
-- Name: COLUMN datadic_variable_history.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.schema_or_path IS 'Database schema or Filesystem directory path';


--
-- Name: COLUMN datadic_variable_history.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.table_or_file IS 'Database table (or view, if derived or equivalent to another variable), or filename in directory';


--
-- Name: COLUMN datadic_variable_history.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.redcap_data_dictionary_id IS 'Reference to REDCap data dictionary representation';


--
-- Name: COLUMN datadic_variable_history."position"; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history."position" IS 'Relative position (for source forms or other variables where order of collection matters)';


--
-- Name: COLUMN datadic_variable_history.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.section_id IS 'Section this belongs to';


--
-- Name: COLUMN datadic_variable_history.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.sub_section_id IS 'Sub-section this belongs to';


--
-- Name: COLUMN datadic_variable_history.title; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.title IS 'Section caption';


--
-- Name: COLUMN datadic_variable_history.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variable_history.storage_varname IS 'Database field name, or variable name in data file';


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_variable_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_variable_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_variable_history_id_seq OWNED BY ref_data.datadic_variable_history.id;


--
-- Name: datadic_variables; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.datadic_variables (
    id bigint NOT NULL,
    study character varying,
    source_name character varying,
    source_type character varying,
    domain character varying,
    form_name character varying,
    variable_name character varying,
    variable_type character varying,
    presentation_type character varying,
    label character varying,
    label_note character varying,
    annotation character varying,
    is_required boolean,
    valid_type character varying,
    valid_min character varying,
    valid_max character varying,
    multi_valid_choices character varying[],
    is_identifier boolean,
    is_derived_var boolean,
    multi_derived_from_id bigint[],
    doc_url character varying,
    target_type character varying,
    owner_email character varying,
    classification character varying,
    other_classification character varying,
    multi_timepoints character varying[],
    equivalent_to_id bigint,
    storage_type character varying,
    db_or_fs character varying,
    schema_or_path character varying,
    table_or_file character varying,
    disabled boolean,
    admin_id bigint,
    redcap_data_dictionary_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer,
    section_id integer,
    sub_section_id integer,
    title character varying,
    storage_varname character varying
);


--
-- Name: COLUMN datadic_variables.study; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.study IS 'Study name';


--
-- Name: COLUMN datadic_variables.source_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.source_name IS 'Source of variable';


--
-- Name: COLUMN datadic_variables.source_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.source_type IS 'Source type';


--
-- Name: COLUMN datadic_variables.domain; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.domain IS 'Domain';


--
-- Name: COLUMN datadic_variables.form_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.form_name IS 'Form name (if the source was a type of form)';


--
-- Name: COLUMN datadic_variables.variable_name; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.variable_name IS 'Variable name (as stored)';


--
-- Name: COLUMN datadic_variables.variable_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.variable_type IS 'Variable type';


--
-- Name: COLUMN datadic_variables.presentation_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.presentation_type IS 'Data type for presentation purposes';


--
-- Name: COLUMN datadic_variables.label; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.label IS 'Primary label or title (if source was a form, the label presented for the field)';


--
-- Name: COLUMN datadic_variables.label_note; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.label_note IS 'Description (if source was a form, a note presented for the field)';


--
-- Name: COLUMN datadic_variables.annotation; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.annotation IS 'Annotations (if source was a form, annotations not presented to the user)';


--
-- Name: COLUMN datadic_variables.is_required; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_required IS 'Was required in source';


--
-- Name: COLUMN datadic_variables.valid_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_type IS 'Source data type';


--
-- Name: COLUMN datadic_variables.valid_min; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_min IS 'Minimum value';


--
-- Name: COLUMN datadic_variables.valid_max; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.valid_max IS 'Maximum value';


--
-- Name: COLUMN datadic_variables.multi_valid_choices; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_valid_choices IS 'List of valid choices for categorical variables';


--
-- Name: COLUMN datadic_variables.is_identifier; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_identifier IS 'Represents identifiable information';


--
-- Name: COLUMN datadic_variables.is_derived_var; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.is_derived_var IS 'Is a derived variable';


--
-- Name: COLUMN datadic_variables.multi_derived_from_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_derived_from_id IS 'If a derived variable, ids of variables used to calculate it';


--
-- Name: COLUMN datadic_variables.doc_url; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.doc_url IS 'URL to additional documentation';


--
-- Name: COLUMN datadic_variables.target_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.target_type IS 'Type of participant this variable relates to';


--
-- Name: COLUMN datadic_variables.owner_email; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.owner_email IS 'Owner, especially for derived variables';


--
-- Name: COLUMN datadic_variables.classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.classification IS 'Category of sensitivity from a privacy perspective';


--
-- Name: COLUMN datadic_variables.other_classification; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.other_classification IS 'Additional information regarding classification';


--
-- Name: COLUMN datadic_variables.multi_timepoints; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.multi_timepoints IS 'Timepoints this data is collected (in longitudinal studies)';


--
-- Name: COLUMN datadic_variables.equivalent_to_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.equivalent_to_id IS 'Primary variable id this is equivalent to';


--
-- Name: COLUMN datadic_variables.storage_type; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.storage_type IS 'Type of storage for dataset';


--
-- Name: COLUMN datadic_variables.db_or_fs; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.db_or_fs IS 'Database or Filesystem name';


--
-- Name: COLUMN datadic_variables.schema_or_path; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.schema_or_path IS 'Database schema or Filesystem directory path';


--
-- Name: COLUMN datadic_variables.table_or_file; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.table_or_file IS 'Database table (or view, if derived or equivalent to another variable), or filename in directory';


--
-- Name: COLUMN datadic_variables.redcap_data_dictionary_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.redcap_data_dictionary_id IS 'Reference to REDCap data dictionary representation';


--
-- Name: COLUMN datadic_variables."position"; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables."position" IS 'Relative position (for source forms or other variables where order of collection matters)';


--
-- Name: COLUMN datadic_variables.section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.section_id IS 'Section this belongs to';


--
-- Name: COLUMN datadic_variables.sub_section_id; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.sub_section_id IS 'Sub-section this belongs to';


--
-- Name: COLUMN datadic_variables.title; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.title IS 'Section caption';


--
-- Name: COLUMN datadic_variables.storage_varname; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON COLUMN ref_data.datadic_variables.storage_varname IS 'Database field name, or variable name in data file';


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.datadic_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datadic_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.datadic_variables_id_seq OWNED BY ref_data.datadic_variables.id;


--
-- Name: redcap_client_requests; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_client_requests (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    action character varying,
    name character varying,
    server_url character varying,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    result jsonb
);


--
-- Name: TABLE redcap_client_requests; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_client_requests IS 'Redcap client requests';


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_client_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_client_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_client_requests_id_seq OWNED BY ref_data.redcap_client_requests.id;


--
-- Name: redcap_data_dictionaries; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_dictionaries (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE redcap_data_dictionaries; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_data_dictionaries IS 'Retrieved Redcap Data Dictionaries (metadata)';


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_dictionaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_dictionaries_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_dictionaries_id_seq OWNED BY ref_data.redcap_data_dictionaries.id;


--
-- Name: redcap_data_dictionary_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_data_dictionary_history (
    id bigint NOT NULL,
    redcap_data_dictionary_id bigint,
    redcap_project_admin_id bigint,
    field_count integer,
    captured_metadata jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE redcap_data_dictionary_history; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_data_dictionary_history IS 'Retrieved Redcap Data Dictionaries (metadata) - history';


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_data_dictionary_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_data_dictionary_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_data_dictionary_history_id_seq OWNED BY ref_data.redcap_data_dictionary_history.id;


--
-- Name: redcap_project_admin_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_admin_history (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] DEFAULT '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying
);


--
-- Name: TABLE redcap_project_admin_history; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_project_admin_history IS 'Redcap project administration - history';


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_admin_history_id_seq OWNED BY ref_data.redcap_project_admin_history.id;


--
-- Name: redcap_project_admins; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_admins (
    id bigint NOT NULL,
    name character varying,
    api_key character varying,
    server_url character varying,
    captured_project_info jsonb,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    transfer_mode character varying,
    frequency character varying,
    status character varying,
    post_transfer_pipeline character varying[] DEFAULT '{}'::character varying[],
    notes character varying,
    study character varying,
    dynamic_model_table character varying,
    options character varying
);


--
-- Name: TABLE redcap_project_admins; Type: COMMENT; Schema: ref_data; Owner: -
--

COMMENT ON TABLE ref_data.redcap_project_admins IS 'Redcap project administration';


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_admins_id_seq OWNED BY ref_data.redcap_project_admins.id;


--
-- Name: redcap_project_user_history; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_user_history (
    id bigint NOT NULL,
    redcap_project_user_id bigint,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_user_history_id_seq OWNED BY ref_data.redcap_project_user_history.id;


--
-- Name: redcap_project_users; Type: TABLE; Schema: ref_data; Owner: -
--

CREATE TABLE ref_data.redcap_project_users (
    id bigint NOT NULL,
    redcap_project_admin_id bigint,
    username character varying,
    email character varying,
    expiration character varying,
    disabled boolean,
    admin_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE; Schema: ref_data; Owner: -
--

CREATE SEQUENCE ref_data.redcap_project_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redcap_project_users_id_seq; Type: SEQUENCE OWNED BY; Schema: ref_data; Owner: -
--

ALTER SEQUENCE ref_data.redcap_project_users_id_seq OWNED BY ref_data.redcap_project_users.id;


--
-- Name: datadic_choice_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_choice_history_id_seq'::regclass);


--
-- Name: datadic_choices id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_choices_id_seq'::regclass);


--
-- Name: datadic_variable_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_variable_history_id_seq'::regclass);


--
-- Name: datadic_variables id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables ALTER COLUMN id SET DEFAULT nextval('ref_data.datadic_variables_id_seq'::regclass);


--
-- Name: redcap_client_requests id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_client_requests_id_seq'::regclass);


--
-- Name: redcap_data_dictionaries id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_dictionaries_id_seq'::regclass);


--
-- Name: redcap_data_dictionary_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_data_dictionary_history_id_seq'::regclass);


--
-- Name: redcap_project_admin_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_admin_history_id_seq'::regclass);


--
-- Name: redcap_project_admins id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admins ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_admins_id_seq'::regclass);


--
-- Name: redcap_project_user_history id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_user_history_id_seq'::regclass);


--
-- Name: redcap_project_users id; Type: DEFAULT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users ALTER COLUMN id SET DEFAULT nextval('ref_data.redcap_project_users_id_seq'::regclass);


--
-- Name: datadic_choice_history datadic_choice_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT datadic_choice_history_pkey PRIMARY KEY (id);


--
-- Name: datadic_choices datadic_choices_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices
    ADD CONSTRAINT datadic_choices_pkey PRIMARY KEY (id);


--
-- Name: datadic_variable_history datadic_variable_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT datadic_variable_history_pkey PRIMARY KEY (id);


--
-- Name: datadic_variables datadic_variables_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT datadic_variables_pkey PRIMARY KEY (id);


--
-- Name: redcap_client_requests redcap_client_requests_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests
    ADD CONSTRAINT redcap_client_requests_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_dictionaries redcap_data_dictionaries_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT redcap_data_dictionaries_pkey PRIMARY KEY (id);


--
-- Name: redcap_data_dictionary_history redcap_data_dictionary_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT redcap_data_dictionary_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_admin_history redcap_project_admin_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history
    ADD CONSTRAINT redcap_project_admin_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_admins redcap_project_admins_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admins
    ADD CONSTRAINT redcap_project_admins_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_user_history redcap_project_user_history_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT redcap_project_user_history_pkey PRIMARY KEY (id);


--
-- Name: redcap_project_users redcap_project_users_pkey; Type: CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT redcap_project_users_pkey PRIMARY KEY (id);


--
-- Name: idx_dch_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dch_on_redcap_dd_id ON ref_data.datadic_choice_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_dv_equiv; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dv_equiv ON ref_data.datadic_variables USING btree (equivalent_to_id);


--
-- Name: idx_dvh_equiv; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dvh_equiv ON ref_data.datadic_variable_history USING btree (equivalent_to_id);


--
-- Name: idx_dvh_on_redcap_dd_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_dvh_on_redcap_dd_id ON ref_data.datadic_variable_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_h_on_datadic_variable_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_datadic_variable_id ON ref_data.datadic_variable_history USING btree (datadic_variable_id);


--
-- Name: idx_h_on_proj_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_proj_admin_id ON ref_data.redcap_project_user_history USING btree (redcap_project_admin_id);


--
-- Name: idx_h_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_redcap_admin_id ON ref_data.redcap_data_dictionary_history USING btree (redcap_project_admin_id);


--
-- Name: idx_h_on_redcap_project_user_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_h_on_redcap_project_user_id ON ref_data.redcap_project_user_history USING btree (redcap_project_user_id);


--
-- Name: idx_history_on_datadic_choice_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_datadic_choice_id ON ref_data.datadic_choice_history USING btree (datadic_choice_id);


--
-- Name: idx_history_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_redcap_data_dictionary_id ON ref_data.redcap_data_dictionary_history USING btree (redcap_data_dictionary_id);


--
-- Name: idx_history_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_history_on_redcap_project_admin_id ON ref_data.redcap_project_admin_history USING btree (redcap_project_admin_id);


--
-- Name: idx_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_on_redcap_admin_id ON ref_data.redcap_data_dictionaries USING btree (redcap_project_admin_id);


--
-- Name: idx_rcr_on_redcap_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX idx_rcr_on_redcap_admin_id ON ref_data.redcap_client_requests USING btree (redcap_project_admin_id);


--
-- Name: index_ref_data.datadic_choice_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choice_history_on_admin_id" ON ref_data.datadic_choice_history USING btree (admin_id);


--
-- Name: index_ref_data.datadic_choices_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choices_on_admin_id" ON ref_data.datadic_choices USING btree (admin_id);


--
-- Name: index_ref_data.datadic_choices_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_choices_on_redcap_data_dictionary_id" ON ref_data.datadic_choices USING btree (redcap_data_dictionary_id);


--
-- Name: index_ref_data.datadic_variable_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variable_history_on_admin_id" ON ref_data.datadic_variable_history USING btree (admin_id);


--
-- Name: index_ref_data.datadic_variables_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variables_on_admin_id" ON ref_data.datadic_variables USING btree (admin_id);


--
-- Name: index_ref_data.datadic_variables_on_redcap_data_dictionary_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.datadic_variables_on_redcap_data_dictionary_id" ON ref_data.datadic_variables USING btree (redcap_data_dictionary_id);


--
-- Name: index_ref_data.redcap_client_requests_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_client_requests_on_admin_id" ON ref_data.redcap_client_requests USING btree (admin_id);


--
-- Name: index_ref_data.redcap_data_dictionaries_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_data_dictionaries_on_admin_id" ON ref_data.redcap_data_dictionaries USING btree (admin_id);


--
-- Name: index_ref_data.redcap_data_dictionary_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_data_dictionary_history_on_admin_id" ON ref_data.redcap_data_dictionary_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_admin_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_admin_history_on_admin_id" ON ref_data.redcap_project_admin_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_admins_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_admins_on_admin_id" ON ref_data.redcap_project_admins USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_user_history_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_user_history_on_admin_id" ON ref_data.redcap_project_user_history USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_users_on_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_users_on_admin_id" ON ref_data.redcap_project_users USING btree (admin_id);


--
-- Name: index_ref_data.redcap_project_users_on_redcap_project_admin_id; Type: INDEX; Schema: ref_data; Owner: -
--

CREATE INDEX "index_ref_data.redcap_project_users_on_redcap_project_admin_id" ON ref_data.redcap_project_users USING btree (redcap_project_admin_id);


--
-- Name: datadic_choices log_datadic_choice_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_choice_history_insert AFTER INSERT ON ref_data.datadic_choices FOR EACH ROW EXECUTE PROCEDURE ml_app.datadic_choice_history_upd();


--
-- Name: datadic_choices log_datadic_choice_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_choice_history_update AFTER UPDATE ON ref_data.datadic_choices FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.datadic_choice_history_upd();


--
-- Name: datadic_variables log_datadic_variable_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_variable_history_insert AFTER INSERT ON ref_data.datadic_variables FOR EACH ROW EXECUTE PROCEDURE ml_app.datadic_variable_history_upd();


--
-- Name: datadic_variables log_datadic_variable_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_datadic_variable_history_update AFTER UPDATE ON ref_data.datadic_variables FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.datadic_variable_history_upd();


--
-- Name: redcap_data_dictionaries log_redcap_data_dictionary_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_dictionary_history_insert AFTER INSERT ON ref_data.redcap_data_dictionaries FOR EACH ROW EXECUTE PROCEDURE ml_app.redcap_data_dictionary_history_upd();


--
-- Name: redcap_data_dictionaries log_redcap_data_dictionary_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_data_dictionary_history_update AFTER UPDATE ON ref_data.redcap_data_dictionaries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.redcap_data_dictionary_history_upd();


--
-- Name: redcap_project_admins log_redcap_project_admin_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_admin_history_insert AFTER INSERT ON ref_data.redcap_project_admins FOR EACH ROW EXECUTE PROCEDURE ml_app.redcap_project_admin_history_upd();


--
-- Name: redcap_project_admins log_redcap_project_admin_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_admin_history_update AFTER UPDATE ON ref_data.redcap_project_admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.redcap_project_admin_history_upd();


--
-- Name: redcap_project_users log_redcap_project_user_history_insert; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_user_history_insert AFTER INSERT ON ref_data.redcap_project_users FOR EACH ROW EXECUTE PROCEDURE ml_app.redcap_project_user_history_upd();


--
-- Name: redcap_project_users log_redcap_project_user_history_update; Type: TRIGGER; Schema: ref_data; Owner: -
--

CREATE TRIGGER log_redcap_project_user_history_update AFTER UPDATE ON ref_data.redcap_project_users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.redcap_project_user_history_upd();


--
-- Name: datadic_variables fk_rails_029902d3e3; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_029902d3e3 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: datadic_variable_history fk_rails_143e8a7c25; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_143e8a7c25 FOREIGN KEY (equivalent_to_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: redcap_data_dictionaries fk_rails_16cfa46407; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT fk_rails_16cfa46407 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: redcap_data_dictionary_history fk_rails_25f366a78c; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_25f366a78c FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: redcap_client_requests fk_rails_32285f308d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_client_requests
    ADD CONSTRAINT fk_rails_32285f308d FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: datadic_variables fk_rails_34eadb0aee; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_34eadb0aee FOREIGN KEY (equivalent_to_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: redcap_project_users fk_rails_38d0954914; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT fk_rails_38d0954914 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: datadic_choice_history fk_rails_42389740a0; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT fk_rails_42389740a0 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: redcap_data_dictionaries fk_rails_4766ebe50f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionaries
    ADD CONSTRAINT fk_rails_4766ebe50f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: datadic_variable_history fk_rails_5302a77293; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_5302a77293 FOREIGN KEY (datadic_variable_id) REFERENCES ref_data.datadic_variables(id);


--
-- Name: datadic_variables fk_rails_5578e37430; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variables
    ADD CONSTRAINT fk_rails_5578e37430 FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: datadic_choice_history fk_rails_63103b7cf7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT fk_rails_63103b7cf7 FOREIGN KEY (datadic_choice_id) REFERENCES ref_data.datadic_choices(id);


--
-- Name: datadic_choices fk_rails_67ca4d7e1f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices
    ADD CONSTRAINT fk_rails_67ca4d7e1f FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: datadic_variable_history fk_rails_6ba6ab1e1f; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_6ba6ab1e1f FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: redcap_project_user_history fk_rails_7ba2e90d7d; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_7ba2e90d7d FOREIGN KEY (redcap_project_user_id) REFERENCES ref_data.redcap_project_users(id);


--
-- Name: redcap_project_user_history fk_rails_89af917107; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_89af917107 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: redcap_data_dictionary_history fk_rails_9a6eca0fe7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_9a6eca0fe7 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: redcap_project_user_history fk_rails_a0bf0fdddb; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_user_history
    ADD CONSTRAINT fk_rails_a0bf0fdddb FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: redcap_project_users fk_rails_a6952cc0e8; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_users
    ADD CONSTRAINT fk_rails_a6952cc0e8 FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: redcap_project_admin_history fk_rails_a7610f4fec; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_project_admin_history
    ADD CONSTRAINT fk_rails_a7610f4fec FOREIGN KEY (redcap_project_admin_id) REFERENCES ref_data.redcap_project_admins(id);


--
-- Name: datadic_choice_history fk_rails_cb8a1e9d10; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choice_history
    ADD CONSTRAINT fk_rails_cb8a1e9d10 FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: datadic_variable_history fk_rails_d7e89fcbde; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_variable_history
    ADD CONSTRAINT fk_rails_d7e89fcbde FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- Name: datadic_choices fk_rails_f5497a3583; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.datadic_choices
    ADD CONSTRAINT fk_rails_f5497a3583 FOREIGN KEY (redcap_data_dictionary_id) REFERENCES ref_data.redcap_data_dictionaries(id);


--
-- Name: redcap_data_dictionary_history fk_rails_fffede9aa7; Type: FK CONSTRAINT; Schema: ref_data; Owner: -
--

ALTER TABLE ONLY ref_data.redcap_data_dictionary_history
    ADD CONSTRAINT fk_rails_fffede9aa7 FOREIGN KEY (admin_id) REFERENCES ml_app.admins(id);


--
-- PostgreSQL database dump complete
--

commit;
