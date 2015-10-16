--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET search_path = public, pg_catalog;

--
-- Name: log_accuracy_score_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_accuracy_score_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO accuracy_score_history
            (
                    accuracy_score_id,
                    name ,
                    value ,                    
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id                      
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.value ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id                      
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_address_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_address_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO address_history 
                (
                    master_id,
                    street,
                    street2,
                    street3,
                    city,
                    state,
                    zip,
                    source,
                    rank,
                    rec_type,
                    user_id,
                    created_at,
                    updated_at,
                    country,
                    postal_code,
                    region,
                    address_id
                )
                 
            SELECT                 
                NEW.master_id,
                NEW.street,
                NEW.street2,
                NEW.street3,
                NEW.city,
                NEW.state,
                NEW.zip,
                NEW.source,
                NEW.rank,
                NEW.rec_type,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.country,
                NEW.postal_code,
                NEW.region,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_admin_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_admin_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO admin_history
            (
                    admin_id,
    email,
    encrypted_password,    
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,    
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_college_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_college_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO college_history
            (
                    college_id,
                    name ,
                    synonym_for_id,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id,
                    user_id            
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.synonym_for_id ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id,
                    NEW.user_id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_general_selection_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_general_selection_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO general_selection_history
            (
                    general_selection_id,
                    name ,
                    value ,
                    item_type ,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id ,
                    create_with ,
                    edit_if_set ,
                    edit_always ,
                    position ,
                    description ,
                    lock 
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                NEW.value ,
                NEW.item_type ,
                NEW.created_at ,
                NEW.updated_at ,
                NEW.disabled ,
                NEW.admin_id ,
                NEW.create_with ,
                NEW.edit_if_set ,
                NEW.edit_always ,
                NEW.position "position",
                NEW.description ,
                NEW.lock
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_item_flag_name_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_item_flag_name_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_name_history
            (
                    item_flag_name_id,
                    name ,
                    item_type,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.item_type ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_item_flag_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_item_flag_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_history
            (
                    item_flag_id,
                    item_id ,
                    item_type,
                    item_flag_name_id,
                    created_at ,
                    updated_at ,
                    user_id 
                )                 
            SELECT                 
                NEW.id,
                NEW.item_id ,
                    NEW.item_type,
                    NEW.item_flag_name_id,
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.user_id 
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_player_contact_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_player_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO player_contact_history
            (
                    player_contact_id,
                    master_id,
                    rec_type,
                    data,
                    source,
                    rank,
                    user_id,
                    created_at,
                    updated_at
                )                 
            SELECT                 
                NEW.id,
                NEW.master_id,
                NEW.rec_type,
                NEW.data,
                NEW.source,
                NEW.rank,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_player_info_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_player_info_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO player_info_history
            (
                    master_id,
                    first_name,
                    last_name,
                    middle_name,
                    nick_name,
                    birth_date,
                    death_date,
                    user_id,
                    created_at,
                    updated_at,
                    contact_pref,
                    start_year,
                    rank,
                    notes,
                    contact_id,
                    college,
                    end_year,
                    source,
                    player_info_id
                )                 
            SELECT
                NEW.master_id,
                NEW.first_name,
                NEW.last_name,
                NEW.middle_name,
                NEW.nick_name,
                NEW.birth_date,
                NEW.death_date,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.contact_pref,
                NEW.start_year,
                NEW.rank,
                NEW.notes,
                NEW.contact_id,
                NEW.college,
                NEW.end_year,
                NEW.source, 
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_protocol_event_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_protocol_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_event_history
            (
                    protocol_event_id,                    
    name ,
    admin_id,
    created_at,
    updated_at,
    disabled ,
    sub_process_id,
    milestone ,
    description

                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.disabled ,
    NEW.sub_process_id,
    NEW.milestone ,
    NEW.description
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_protocol_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_protocol_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_history
            (
                    protocol_id,
                    name ,                    
                    created_at ,
                    updated_at ,
                    disabled,
                    admin_id ,
                    "position"
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled,
                    NEW.admin_id ,
                    NEW.position
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_scantron_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_scantron_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO scantron_history
            (
                master_id,
                scantron_id,
                user_id,
                created_at,
                updated_at,
                scantron_table_id
                )                 
            SELECT
                NEW.master_id,
                NEW.scantron_id,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_sub_process_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_sub_process_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sub_process_history
            (
                    sub_process_id,                    
    
    name,
    disabled,
    protocol_id,
    admin_id ,
    created_at,
    updated_at

                )                 
            SELECT                 
                NEW.id,
                NEW.name,
    NEW.disabled,
    NEW.protocol_id,
    NEW.admin_id ,
    NEW.created_at,
    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_tracker_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_tracker_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO tracker_history 
                (tracker_id, master_id, protocol_id, 
                 protocol_event_id, event_date, sub_process_id, notes,
                 item_id, item_type,
                 created_at, updated_at, user_id)
                 
            SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                   NEW.protocol_event_id, NEW.event_date, 
                   NEW.sub_process_id, NEW.notes, 
                   NEW.item_id, NEW.item_type,
                   NEW.created_at, NEW.updated_at, NEW.user_id  ;
            RETURN NEW;
        END;
    $$;


--
-- Name: log_user_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION log_user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_history
            (
                    user_id,
    email,
    encrypted_password,
    reset_password_token,
    reset_password_sent_at,
    remember_created_at,
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled ,
    admin_id 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,
    NEW.reset_password_token,
    NEW.reset_password_sent_at,
    NEW.remember_created_at,
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled ,
    NEW.admin_id  
            ;
            RETURN NEW;
        END;
    $$;


--
-- Name: update_master_with_player_info(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_master_with_player_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE masters 
            set rank = (
            case when NEW.rank is null then -1000 
                 when (NEW.rank > 12) then NEW.rank * -1 
                 else new.rank
            end
            )

        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $$;


--
-- Name: update_master_with_pro_info(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_master_with_pro_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE masters 
            set pro_info_id = NEW.id, pro_id = NEW.pro_id             
        WHERE masters.id = NEW.master_id;

        RETURN NEW;
    END;
    $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accuracy_score_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accuracy_score_history (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    accuracy_score_id integer
);


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_score_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accuracy_score_history_id_seq OWNED BY accuracy_score_history.id;


--
-- Name: accuracy_scores; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE accuracy_scores (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accuracy_scores_id_seq OWNED BY accuracy_scores.id;


--
-- Name: address_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE address_history (
    id integer NOT NULL,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    country character varying(3),
    postal_code character varying,
    region character varying,
    address_id integer
);


--
-- Name: address_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE address_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE address_history_id_seq OWNED BY address_history.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    country character varying(3),
    postal_code character varying,
    region character varying
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admin_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admin_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean,
    admin_id integer
);


--
-- Name: admin_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_history_id_seq OWNED BY admin_history.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE admins (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: college_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE college_history (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    college_id integer
);


--
-- Name: college_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: college_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE college_history_id_seq OWNED BY college_history.id;


--
-- Name: colleges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE colleges (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE colleges_id_seq OWNED BY colleges.id;


--
-- Name: external_links; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE external_links (
    id integer NOT NULL,
    name character varying,
    value character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE external_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_links_id_seq OWNED BY external_links.id;


--
-- Name: general_selection_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE general_selection_history (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean,
    general_selection_id integer
);


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selection_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE general_selection_history_id_seq OWNED BY general_selection_history.id;


--
-- Name: general_selections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE general_selections (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean
);


--
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE general_selections_id_seq OWNED BY general_selections.id;


--
-- Name: item_flag_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_history (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    item_flag_id integer
);


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_flag_history_id_seq OWNED BY item_flag_history.id;


--
-- Name: item_flag_name_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_name_history (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    disabled boolean,
    admin_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    item_flag_name_id integer
);


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_name_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_flag_name_history_id_seq OWNED BY item_flag_name_history.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_flag_names (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_flag_names_id_seq OWNED BY item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE item_flags (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE item_flags_id_seq OWNED BY item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE manage_users_id_seq OWNED BY manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE masters (
    id integer NOT NULL,
    msid integer,
    pro_id integer,
    pro_info_id integer,
    rank integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE masters_id_seq OWNED BY masters.id;


--
-- Name: msid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE msid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contact_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_contact_history (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    player_contact_id integer
);


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contact_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_contact_history_id_seq OWNED BY player_contact_history.id;


--
-- Name: player_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_contacts (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_contacts_id_seq OWNED BY player_contacts.id;


--
-- Name: player_info_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_info_history (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying,
    player_info_id integer
);


--
-- Name: player_info_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_info_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_info_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_info_history_id_seq OWNED BY player_info_history.id;


--
-- Name: player_infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE player_infos (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    contact_pref character varying,
    start_year integer,
    rank integer,
    notes character varying,
    contact_id integer,
    college character varying,
    end_year integer,
    source character varying
);


--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE player_infos_id_seq OWNED BY player_infos.id;


--
-- Name: pro_infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pro_infos (
    id integer NOT NULL,
    master_id integer,
    pro_id integer,
    first_name character varying,
    middle_name character varying,
    nick_name character varying,
    last_name character varying,
    birth_date date,
    death_date date,
    start_year integer,
    end_year integer,
    college character varying,
    birthplace character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pro_infos_id_seq OWNED BY pro_infos.id;


--
-- Name: protocol_event_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protocol_event_history (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying,
    protocol_event_id integer
);


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_event_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE protocol_event_history_id_seq OWNED BY protocol_event_history.id;


--
-- Name: protocol_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protocol_events (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying
);


--
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE protocol_events_id_seq OWNED BY protocol_events.id;


--
-- Name: protocol_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protocol_history (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer,
    protocol_id integer
);


--
-- Name: protocol_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocol_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE protocol_history_id_seq OWNED BY protocol_history.id;


--
-- Name: protocols; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer
);


--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE protocols_id_seq OWNED BY protocols.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reports (
    id integer NOT NULL,
    name character varying,
    description character varying,
    sql character varying,
    search_attrs character varying,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    report_type character varying,
    auto boolean,
    searchable boolean,
    "position" integer
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: scantron_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scantron_history (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    scantron_table_id integer
);


--
-- Name: scantron_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scantron_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantron_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scantron_history_id_seq OWNED BY scantron_history.id;


--
-- Name: scantrons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scantrons (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scantrons_id_seq OWNED BY scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sub_process_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sub_process_history (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sub_process_id integer
);


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_process_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sub_process_history_id_seq OWNED BY sub_process_history.id;


--
-- Name: sub_processes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sub_processes (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sub_processes_id_seq OWNED BY sub_processes.id;


--
-- Name: test_table; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_table (
    abcid integer,
    somestring character varying,
    testing boolean
);


--
-- Name: tracker_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracker_history (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    tracker_id integer,
    event_date timestamp without time zone,
    user_id integer,
    notes character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


--
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracker_history_id_seq OWNED BY tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    event_date timestamp without time zone,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes character varying,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;


--
-- Name: user_history; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,
    user_id integer
);


--
-- Name: user_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_history_id_seq OWNED BY user_history.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('accuracy_score_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accuracy_scores ALTER COLUMN id SET DEFAULT nextval('accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY address_history ALTER COLUMN id SET DEFAULT nextval('address_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_history ALTER COLUMN id SET DEFAULT nextval('admin_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY college_history ALTER COLUMN id SET DEFAULT nextval('college_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY colleges ALTER COLUMN id SET DEFAULT nextval('colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_links ALTER COLUMN id SET DEFAULT nextval('external_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY general_selection_history ALTER COLUMN id SET DEFAULT nextval('general_selection_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY general_selections ALTER COLUMN id SET DEFAULT nextval('general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_history ALTER COLUMN id SET DEFAULT nextval('item_flag_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('item_flag_name_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_names ALTER COLUMN id SET DEFAULT nextval('item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flags ALTER COLUMN id SET DEFAULT nextval('item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY manage_users ALTER COLUMN id SET DEFAULT nextval('manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY masters ALTER COLUMN id SET DEFAULT nextval('masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contact_history ALTER COLUMN id SET DEFAULT nextval('player_contact_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contacts ALTER COLUMN id SET DEFAULT nextval('player_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_info_history ALTER COLUMN id SET DEFAULT nextval('player_info_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_infos ALTER COLUMN id SET DEFAULT nextval('player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pro_infos ALTER COLUMN id SET DEFAULT nextval('pro_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_event_history ALTER COLUMN id SET DEFAULT nextval('protocol_event_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_events ALTER COLUMN id SET DEFAULT nextval('protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_history ALTER COLUMN id SET DEFAULT nextval('protocol_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantron_history ALTER COLUMN id SET DEFAULT nextval('scantron_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantrons ALTER COLUMN id SET DEFAULT nextval('scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_process_history ALTER COLUMN id SET DEFAULT nextval('sub_process_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_processes ALTER COLUMN id SET DEFAULT nextval('sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history ALTER COLUMN id SET DEFAULT nextval('tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers ALTER COLUMN id SET DEFAULT nextval('trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_history ALTER COLUMN id SET DEFAULT nextval('user_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: accuracy_score_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: address_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT address_history_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: college_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: external_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_links
    ADD CONSTRAINT external_links_pkey PRIMARY KEY (id);


--
-- Name: general_selection_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: item_flag_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_name_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: player_contact_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT player_contact_history_pkey PRIMARY KEY (id);


--
-- Name: player_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_info_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT player_info_history_pkey PRIMARY KEY (id);


--
-- Name: player_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_event_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocol_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: scantron_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT scantron_history_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: sub_process_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: user_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_accuracy_score_history_on_accuracy_score_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON accuracy_score_history USING btree (accuracy_score_id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_accuracy_scores_on_admin_id ON accuracy_scores USING btree (admin_id);


--
-- Name: index_address_history_on_address_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_address_id ON address_history USING btree (address_id);


--
-- Name: index_address_history_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_master_id ON address_history USING btree (master_id);


--
-- Name: index_address_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_address_history_on_user_id ON address_history USING btree (user_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_master_id ON addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_addresses_on_user_id ON addresses USING btree (user_id);


--
-- Name: index_admin_history_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_history_on_admin_id ON admin_history USING btree (admin_id);


--
-- Name: index_college_history_on_college_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_college_history_on_college_id ON college_history USING btree (college_id);


--
-- Name: index_colleges_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_colleges_on_admin_id ON colleges USING btree (admin_id);


--
-- Name: index_colleges_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_colleges_on_user_id ON colleges USING btree (user_id);


--
-- Name: index_external_links_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_external_links_on_admin_id ON external_links USING btree (admin_id);


--
-- Name: index_general_selection_history_on_general_selection_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_general_selection_history_on_general_selection_id ON general_selection_history USING btree (general_selection_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_general_selections_on_admin_id ON general_selections USING btree (admin_id);


--
-- Name: index_item_flag_history_on_item_flag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_history_on_item_flag_id ON item_flag_history USING btree (item_flag_id);


--
-- Name: index_item_flag_name_history_on_item_flag_name_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON item_flag_name_history USING btree (item_flag_name_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flag_names_on_admin_id ON item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_item_flags_on_user_id ON item_flags USING btree (user_id);


--
-- Name: index_masters_on_msid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_msid ON masters USING btree (msid);


--
-- Name: index_masters_on_pro_info_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_pro_info_id ON masters USING btree (pro_info_id);


--
-- Name: index_masters_on_proid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_proid ON masters USING btree (pro_id);


--
-- Name: index_masters_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_masters_on_user_id ON masters USING btree (user_id);


--
-- Name: index_player_contact_history_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_master_id ON player_contact_history USING btree (master_id);


--
-- Name: index_player_contact_history_on_player_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_player_contact_id ON player_contact_history USING btree (player_contact_id);


--
-- Name: index_player_contact_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contact_history_on_user_id ON player_contact_history USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contacts_on_master_id ON player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_contacts_on_user_id ON player_contacts USING btree (user_id);


--
-- Name: index_player_info_history_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_master_id ON player_info_history USING btree (master_id);


--
-- Name: index_player_info_history_on_player_info_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_player_info_id ON player_info_history USING btree (player_info_id);


--
-- Name: index_player_info_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_info_history_on_user_id ON player_info_history USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_infos_on_master_id ON player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_player_infos_on_user_id ON player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pro_infos_on_master_id ON pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pro_infos_on_user_id ON pro_infos USING btree (user_id);


--
-- Name: index_protocol_event_history_on_protocol_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON protocol_event_history USING btree (protocol_event_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_events_on_admin_id ON protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_events_on_sub_process_id ON protocol_events USING btree (sub_process_id);


--
-- Name: index_protocol_history_on_protocol_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protocol_history_on_protocol_id ON protocol_history USING btree (protocol_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protocols_on_admin_id ON protocols USING btree (admin_id);


--
-- Name: index_reports_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reports_on_admin_id ON reports USING btree (admin_id);


--
-- Name: index_scantron_history_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_master_id ON scantron_history USING btree (master_id);


--
-- Name: index_scantron_history_on_scantron_table_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_scantron_table_id ON scantron_history USING btree (scantron_table_id);


--
-- Name: index_scantron_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_scantron_history_on_user_id ON scantron_history USING btree (user_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_scantrons_on_master_id ON scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_scantrons_on_user_id ON scantrons USING btree (user_id);


--
-- Name: index_sub_process_history_on_sub_process_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_process_history_on_sub_process_id ON sub_process_history USING btree (sub_process_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_processes_on_admin_id ON sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_processes_on_protocol_id ON sub_processes USING btree (protocol_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_master_id ON tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_id ON tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_sub_process_id ON tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_tracker_id ON tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracker_history_on_user_id ON tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_master_id ON trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_event_id ON trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_id ON trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_sub_process_id ON trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trackers_on_user_id ON trackers USING btree (user_id);


--
-- Name: index_user_history_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_history_on_user_id ON user_history USING btree (user_id);


--
-- Name: index_users_on_admin_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_admin_id ON users USING btree (admin_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: accuracy_score_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON accuracy_scores FOR EACH ROW EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: accuracy_score_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_accuracy_score_update();


--
-- Name: address_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER address_history_insert AFTER INSERT ON addresses FOR EACH ROW EXECUTE PROCEDURE log_address_update();


--
-- Name: address_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER address_history_update AFTER UPDATE ON addresses FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_address_update();


--
-- Name: admin_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER admin_history_insert AFTER INSERT ON admins FOR EACH ROW EXECUTE PROCEDURE log_admin_update();


--
-- Name: admin_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER admin_history_update AFTER UPDATE ON admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_admin_update();


--
-- Name: college_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER college_history_insert AFTER INSERT ON colleges FOR EACH ROW EXECUTE PROCEDURE log_college_update();


--
-- Name: college_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER college_history_update AFTER UPDATE ON colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_college_update();


--
-- Name: general_selection_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON general_selections FOR EACH ROW EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: general_selection_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER general_selection_history_update AFTER UPDATE ON general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_general_selection_update();


--
-- Name: item_flag_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON item_flags FOR EACH ROW EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER item_flag_history_update AFTER UPDATE ON item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_update();


--
-- Name: item_flag_name_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON item_flag_names FOR EACH ROW EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: item_flag_name_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_name_update();


--
-- Name: player_contact_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_contact_history_insert AFTER INSERT ON player_contacts FOR EACH ROW EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_contact_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_contact_history_update AFTER UPDATE ON player_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_contact_update();


--
-- Name: player_info_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_info_history_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_info_history_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_player_info_update();


--
-- Name: player_info_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_info_insert AFTER INSERT ON player_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: player_info_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_info_update AFTER UPDATE ON player_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_player_info();


--
-- Name: pro_info_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pro_info_insert AFTER INSERT ON pro_infos FOR EACH ROW EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: pro_info_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pro_info_update AFTER UPDATE ON pro_infos FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_master_with_pro_info();


--
-- Name: protocol_event_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON protocol_events FOR EACH ROW EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_event_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_event_update();


--
-- Name: protocol_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER protocol_history_insert AFTER INSERT ON protocols FOR EACH ROW EXECUTE PROCEDURE log_protocol_update();


--
-- Name: protocol_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER protocol_history_update AFTER UPDATE ON protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_update();


--
-- Name: scantron_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER scantron_history_insert AFTER INSERT ON scantrons FOR EACH ROW EXECUTE PROCEDURE log_scantron_update();


--
-- Name: scantron_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER scantron_history_update AFTER UPDATE ON scantrons FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_scantron_update();


--
-- Name: sub_process_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON sub_processes FOR EACH ROW EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: sub_process_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sub_process_history_update AFTER UPDATE ON sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sub_process_update();


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tracker_update();


--
-- Name: user_history_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_history_insert AFTER INSERT ON users FOR EACH ROW EXECUTE PROCEDURE log_user_update();


--
-- Name: user_history_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_history_update AFTER UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_update();


--
-- Name: fk_accuracy_score_history_accuracy_scores; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accuracy_score_history
    ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES accuracy_scores(id);


--
-- Name: fk_address_history_addresses; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_addresses FOREIGN KEY (address_id) REFERENCES addresses(id);


--
-- Name: fk_address_history_masters; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_address_history_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY address_history
    ADD CONSTRAINT fk_address_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_admin_history_admins; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_history
    ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_college_history_colleges; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY college_history
    ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES colleges(id);


--
-- Name: fk_general_selection_history_general_selections; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY general_selection_history
    ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES general_selections(id);


--
-- Name: fk_item_flag_history_item_flags; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_history
    ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES item_flags(id);


--
-- Name: fk_item_flag_name_history_item_flag_names; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_name_history
    ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_player_contact_history_masters; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_contact_history_player_contacts; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_player_contacts FOREIGN KEY (player_contact_id) REFERENCES player_contacts(id);


--
-- Name: fk_player_contact_history_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contact_history
    ADD CONSTRAINT fk_player_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_player_info_history_masters; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_player_info_history_player_infos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_player_infos FOREIGN KEY (player_info_id) REFERENCES player_infos(id);


--
-- Name: fk_player_info_history_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_info_history
    ADD CONSTRAINT fk_player_info_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_protocol_event_history_protocol_events; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_event_history
    ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_protocol_history_protocols; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_history
    ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_00b234154d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_00b234154d FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_49306e4f49; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_49306e4f49 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_b0a6220067; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT fk_rails_b0a6220067 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b138baacff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT fk_rails_b138baacff FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_c9d7977c0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT fk_rails_c9d7977c0c FOREIGN KEY (pro_info_id) REFERENCES pro_infos(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_ebf3863277; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_links
    ADD CONSTRAINT fk_rails_ebf3863277 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_scantron_history_masters; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_scantron_history_scantrons; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_scantrons FOREIGN KEY (scantron_table_id) REFERENCES scantrons(id);


--
-- Name: fk_scantron_history_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scantron_history
    ADD CONSTRAINT fk_scantron_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_sub_process_history_sub_processes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_process_history
    ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_user_history_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_history
    ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

