--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
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


SET search_path = public, pg_catalog;

--
-- Name: slugged_class; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE slugged_class AS ENUM (
    'Person',
    'Destination'
);


--
-- Name: state_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE state_type AS ENUM (
    'pending',
    'starting',
    'importing_aircraft',
    'importing_airports',
    'importing_passengers',
    'importing_flights',
    'uploading_photos',
    'completed',
    'failed'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: aircraft; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE aircraft (
    id integer NOT NULL,
    metadata_id integer,
    user_id integer NOT NULL,
    ident character varying(16) NOT NULL,
    has_image boolean DEFAULT false NOT NULL,
    CONSTRAINT aircraft_ident_check CHECK ((char_length((ident)::text) > 0))
);


--
-- Name: aircraft_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE aircraft_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aircraft_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE aircraft_id_seq OWNED BY aircraft.id;


--
-- Name: airports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE airports (
    id integer NOT NULL,
    metadata_id integer,
    site_number character varying(11) NOT NULL,
    lid character varying(4),
    icao character varying(4),
    iata character varying(4),
    CONSTRAINT airports_check CHECK ((((lid IS NOT NULL) OR (icao IS NOT NULL)) OR (iata IS NOT NULL))),
    CONSTRAINT airports_iata_check CHECK ((char_length((iata)::text) > 0)),
    CONSTRAINT airports_icao_check CHECK ((char_length((icao)::text) > 0)),
    CONSTRAINT airports_lid_check CHECK ((char_length((lid)::text) > 0))
);


--
-- Name: airports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE airports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: airports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE airports_id_seq OWNED BY airports.id;


--
-- Name: destinations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE destinations (
    logbook_id integer NOT NULL,
    user_id integer NOT NULL,
    airport_id integer NOT NULL,
    metadata_id integer,
    has_photo boolean DEFAULT false NOT NULL,
    flights_count integer DEFAULT 0 NOT NULL
);


--
-- Name: flights; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flights (
    id integer NOT NULL,
    metadata_id integer,
    logbook_id integer NOT NULL,
    user_id integer NOT NULL,
    origin_id integer NOT NULL,
    destination_id integer NOT NULL,
    aircraft_id integer NOT NULL,
    duration double precision NOT NULL,
    date date NOT NULL,
    has_blog boolean DEFAULT false NOT NULL,
    has_photos boolean DEFAULT false NOT NULL,
    sequence integer,
    CONSTRAINT flights_duration_check CHECK ((duration > (0)::double precision)),
    CONSTRAINT flights_sequence_check CHECK ((sequence >= 1))
);


--
-- Name: flights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flights_id_seq OWNED BY flights.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE imports (
    id integer NOT NULL,
    metadata_id integer,
    user_id integer NOT NULL,
    state state_type DEFAULT 'pending'::state_type NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE imports_id_seq OWNED BY imports.id;


--
-- Name: metadata; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE metadata (
    id integer NOT NULL,
    data text NOT NULL
);


--
-- Name: metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE metadata_id_seq OWNED BY metadata.id;


--
-- Name: occupants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE occupants (
    id integer NOT NULL,
    flight_id integer NOT NULL,
    person_id integer NOT NULL,
    role character varying(126) DEFAULT NULL::character varying
);


--
-- Name: occupants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE occupants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: occupants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE occupants_id_seq OWNED BY occupants.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE people (
    id integer NOT NULL,
    logbook_id integer NOT NULL,
    metadata_id integer,
    user_id integer NOT NULL,
    hours double precision DEFAULT 0 NOT NULL,
    has_photo boolean DEFAULT false NOT NULL,
    me boolean DEFAULT false NOT NULL,
    CONSTRAINT people_hours_check CHECK ((hours >= (0.0)::double precision))
);


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE people_id_seq OWNED BY people.id;


--
-- Name: photographs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE photographs (
    id integer NOT NULL,
    flight_id integer NOT NULL,
    metadata_id integer
);


--
-- Name: photographs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE photographs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photographs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE photographs_id_seq OWNED BY photographs.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: slugs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE slugs (
    id integer NOT NULL,
    sluggable_type slugged_class NOT NULL,
    sluggable_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    slug character varying(126) NOT NULL,
    scope character varying(126),
    created_at timestamp without time zone,
    CONSTRAINT slugs_slug_check CHECK ((char_length((slug)::text) > 0))
);


--
-- Name: slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE slugs_id_seq OWNED BY slugs.id;


--
-- Name: stops; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stops (
    destination_id integer NOT NULL,
    flight_id integer NOT NULL,
    sequence integer NOT NULL,
    CONSTRAINT stops_sequence_check CHECK ((sequence >= 1))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    metadata_id integer,
    email character varying(255) NOT NULL,
    subdomain character varying(32) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    has_avatar boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT users_email_check CHECK ((char_length((email)::text) > 0)),
    CONSTRAINT users_subdomain_check CHECK ((char_length((subdomain)::text) >= 2))
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

ALTER TABLE ONLY aircraft ALTER COLUMN id SET DEFAULT nextval('aircraft_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY airports ALTER COLUMN id SET DEFAULT nextval('airports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights ALTER COLUMN id SET DEFAULT nextval('flights_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports ALTER COLUMN id SET DEFAULT nextval('imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY metadata ALTER COLUMN id SET DEFAULT nextval('metadata_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY occupants ALTER COLUMN id SET DEFAULT nextval('occupants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY people ALTER COLUMN id SET DEFAULT nextval('people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY photographs ALTER COLUMN id SET DEFAULT nextval('photographs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY slugs ALTER COLUMN id SET DEFAULT nextval('slugs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: aircraft_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY aircraft
    ADD CONSTRAINT aircraft_pkey PRIMARY KEY (id);


--
-- Name: airports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY airports
    ADD CONSTRAINT airports_pkey PRIMARY KEY (id);


--
-- Name: airports_site_number_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY airports
    ADD CONSTRAINT airports_site_number_key UNIQUE (site_number);


--
-- Name: flights_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (id);


--
-- Name: occupants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY occupants
    ADD CONSTRAINT occupants_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: photographs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY photographs
    ADD CONSTRAINT photographs_pkey PRIMARY KEY (id);


--
-- Name: slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY slugs
    ADD CONSTRAINT slugs_pkey PRIMARY KEY (id);


--
-- Name: users_email_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_subdomain_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_subdomain_key UNIQUE (subdomain);


--
-- Name: aircraft_ident; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX aircraft_ident ON aircraft USING btree (user_id, ident);


--
-- Name: airports_iata; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX airports_iata ON airports USING btree (iata);


--
-- Name: airports_icao; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX airports_icao ON airports USING btree (icao);


--
-- Name: airports_ident; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX airports_ident ON airports USING btree (lid, icao, iata);


--
-- Name: airports_lid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX airports_lid ON airports USING btree (lid);


--
-- Name: dest_user_photo; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX dest_user_photo ON destinations USING btree (user_id, has_photo);


--
-- Name: destinations_logbook_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX destinations_logbook_id ON destinations USING btree (user_id, logbook_id);


--
-- Name: destinations_pkey; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX destinations_pkey ON destinations USING btree (user_id, airport_id);


--
-- Name: flights_logbook_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX flights_logbook_id ON flights USING btree (user_id, logbook_id);


--
-- Name: flights_user; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX flights_user ON flights USING btree (user_id, sequence);


--
-- Name: flights_user_blog; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX flights_user_blog ON flights USING btree (user_id, has_blog, sequence);


--
-- Name: flights_user_dest; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX flights_user_dest ON flights USING btree (user_id, destination_id, sequence);


--
-- Name: imports_user; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX imports_user ON imports USING btree (user_id, state);


--
-- Name: occupants_flight; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX occupants_flight ON occupants USING btree (flight_id);


--
-- Name: occupants_person; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX occupants_person ON occupants USING btree (person_id);


--
-- Name: people_logbook_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX people_logbook_id ON people USING btree (user_id, logbook_id);


--
-- Name: people_user_me_hours; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX people_user_me_hours ON people USING btree (user_id, me, hours);


--
-- Name: people_user_photo_me_hours; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX people_user_photo_me_hours ON people USING btree (user_id, has_photo, me, hours);


--
-- Name: photographs_flight; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX photographs_flight ON photographs USING btree (flight_id);


--
-- Name: slugs_for_record; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX slugs_for_record ON slugs USING btree (sluggable_type, sluggable_id, active);


--
-- Name: slugs_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX slugs_unique ON slugs USING btree (sluggable_type, scope, slug);


--
-- Name: stops_in_sequence; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX stops_in_sequence ON stops USING btree (flight_id, sequence);


--
-- Name: stops_pkey; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX stops_pkey ON stops USING btree (destination_id, flight_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: aircraft_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aircraft
    ADD CONSTRAINT aircraft_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: aircraft_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY aircraft
    ADD CONSTRAINT aircraft_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: airports_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY airports
    ADD CONSTRAINT airports_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: destinations_airport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY destinations
    ADD CONSTRAINT destinations_airport_id_fkey FOREIGN KEY (airport_id) REFERENCES airports(id) ON DELETE RESTRICT;


--
-- Name: destinations_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY destinations
    ADD CONSTRAINT destinations_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: destinations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY destinations
    ADD CONSTRAINT destinations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: flights_aircraft_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_aircraft_id_fkey FOREIGN KEY (aircraft_id) REFERENCES aircraft(id) ON DELETE RESTRICT;


--
-- Name: flights_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: flights_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: flights_user_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_user_id_fkey1 FOREIGN KEY (user_id, origin_id) REFERENCES destinations(user_id, airport_id) ON DELETE RESTRICT;


--
-- Name: flights_user_id_fkey2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flights
    ADD CONSTRAINT flights_user_id_fkey2 FOREIGN KEY (user_id, destination_id) REFERENCES destinations(user_id, airport_id) ON DELETE RESTRICT;


--
-- Name: imports_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: imports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: occupants_flight_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY occupants
    ADD CONSTRAINT occupants_flight_id_fkey FOREIGN KEY (flight_id) REFERENCES flights(id) ON DELETE CASCADE;


--
-- Name: occupants_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY occupants
    ADD CONSTRAINT occupants_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT;


--
-- Name: people_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: people_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: photographs_flight_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY photographs
    ADD CONSTRAINT photographs_flight_id_fkey FOREIGN KEY (flight_id) REFERENCES flights(id) ON DELETE CASCADE;


--
-- Name: photographs_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY photographs
    ADD CONSTRAINT photographs_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- Name: stops_flight_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stops
    ADD CONSTRAINT stops_flight_id_fkey FOREIGN KEY (flight_id) REFERENCES flights(id) ON DELETE CASCADE;


--
-- Name: users_metadata_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_metadata_id_fkey FOREIGN KEY (metadata_id) REFERENCES metadata(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20110727062432');

INSERT INTO schema_migrations (version) VALUES ('20110727071803');

INSERT INTO schema_migrations (version) VALUES ('20110728041552');

INSERT INTO schema_migrations (version) VALUES ('20120126073137');

INSERT INTO schema_migrations (version) VALUES ('20120126091925');

INSERT INTO schema_migrations (version) VALUES ('20120126093353');

INSERT INTO schema_migrations (version) VALUES ('20120126093404');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');