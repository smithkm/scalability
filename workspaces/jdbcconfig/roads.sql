--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: wfs_roads; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE SEQUENCE wfs_roads_seq;
CREATE TABLE wfs_roads (
    fid integer NOT NULL DEFAULT NEXTVAL('wfs_roads_seq'),
    the_geom geometry(MultiLineString,4326),
    scalerank bigint,
    featurecla character varying(30),
    type character varying(50),
    sov_a3 character varying(3),
    note character varying(50),
    edited character varying(50),
    name character varying(25),
    namealt character varying(25),
    namealtt character varying(30),
    routeraw character varying(50),
    question bigint,
    length_km integer,
    toll integer,
    ne_part character varying(50),
    label character varying(50),
    label2 character varying(50),
    local character varying(30),
    localtype character varying(30),
    localalt character varying(30),
    labelrank integer,
    ignore integer,
    add integer,
    rwdb_rd_id integer,
    orig_fid integer,
    prefix character varying(5),
    uident integer,
    continent character varying(50),
    expressway integer,
    level character varying(50),
    CONSTRAINT enforce_dims_the_geom CHECK ((st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((st_srid(the_geom) = 4326))
);


ALTER TABLE public.wfs_roads OWNER TO postgres;

--
-- Data for Name: wfs_roads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY wfs_roads (fid, the_geom, scalerank, featurecla, type, sov_a3, note, edited, name, namealt, namealtt, routeraw, question, length_km, toll, ne_part, label, label2, local, localtype, localalt, labelrank, ignore, add, rwdb_rd_id, orig_fid, prefix, uident, continent, expressway, level) FROM stdin;
\.


--
-- Name: wfs_roads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY wfs_roads
    ADD CONSTRAINT wfs_roads_pkey PRIMARY KEY (fid);


--
-- Name: wfs_roads_the_geom_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX wfs_roads_the_geom_idx ON wfs_roads USING gist (the_geom);


--
-- PostgreSQL database dump complete
--

