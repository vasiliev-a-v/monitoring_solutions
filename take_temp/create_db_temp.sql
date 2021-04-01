--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Debian 11.7-0+deb10u1)
-- Dumped by pg_dump version 11.11 (Debian 11.11-0+deb10u1)

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
-- Name: pageinspect; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pageinspect WITH SCHEMA public;


--
-- Name: EXTENSION pageinspect; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pageinspect IS 'inspect the contents of database pages at a low level';


--
-- Name: add_not_null_temp(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.add_not_null_temp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if  NEW.temperature = NULL then
      NEW.temperature = OLD.temperature;
  end if;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_not_null_temp() OWNER TO "user";

--
-- Name: add_temp_changes(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.add_temp_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  temp_plus  integer;   -- дополнительная защита от ложного срабатывания
  temp_minus integer;   -- датчиков температур
BEGIN
  temp_plus  := OLD.temperature + 5;  -- датчики DHT11 иногда могут давать
  temp_minus := OLD.temperature - 5;  -- резко завышенную или заниженную температуру

  if  (NEW.temperature < temp_plus ) AND 
      (NEW.temperature > temp_minus) OR
      (NEW.location    = 'Гисметео') then
        INSERT INTO temp_changes
                (location,         time,     temperature)
        VALUES  (NEW.location, NEW.time, NEW.temperature);
        INSERT INTO temp_changes_archive
                (location,         time,     temperature)
        VALUES  (NEW.location, NEW.time, NEW.temperature);
    RETURN NEW;
  end if;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.add_temp_changes() OWNER TO "user";

--
-- Name: remove_old_inserts(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM temp_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.remove_old_inserts() OWNER TO "user";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: locations; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.locations (
    ip inet NOT NULL,
    location text NOT NULL,
    type integer NOT NULL,
    gpio integer NOT NULL,
    blue integer NOT NULL,
    yellow integer NOT NULL,
    red integer NOT NULL,
    correction integer NOT NULL,
    id integer
);


ALTER TABLE public.locations OWNER TO "user";

--
-- Name: temp_changes; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_changes (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temperature integer NOT NULL
);


ALTER TABLE public.temp_changes OWNER TO "user";

--
-- Name: temp_changes_archive; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_changes_archive (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temperature integer NOT NULL
);


ALTER TABLE public.temp_changes_archive OWNER TO "user";

--
-- Name: temp_current; Type: TABLE; Schema: public; Owner: user
--

CREATE UNLOGGED TABLE public.temp_current (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temperature integer NOT NULL
);


ALTER TABLE public.temp_current OWNER TO "user";

--
-- Name: locations locations_location_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_location_key UNIQUE (location);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location);


--
-- Name: temp_current temp_current_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_current
    ADD CONSTRAINT temp_current_pkey PRIMARY KEY (location);


--
-- Name: temp_changes_time_idx; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX temp_changes_time_idx ON public.temp_changes USING btree ("time");


--
-- Name: temp_current trig_if_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_changes AFTER UPDATE ON public.temp_current FOR EACH ROW WHEN ((old.temperature IS DISTINCT FROM new.temperature)) EXECUTE PROCEDURE public.add_temp_changes();


--
-- Name: temp_changes trig_if_insert; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_insert AFTER INSERT ON public.temp_changes FOR EACH STATEMENT EXECUTE PROCEDURE public.remove_old_inserts();


--
-- Name: temp_current trig_if_null; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_null BEFORE INSERT OR UPDATE ON public.temp_current FOR EACH ROW WHEN ((new.temperature = NULL::integer)) EXECUTE PROCEDURE public.add_not_null_temp();


--
-- Name: temp_changes_archive temp_changes_archive_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_changes_archive
    ADD CONSTRAINT temp_changes_archive_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: temp_changes temp_changes_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_changes
    ADD CONSTRAINT temp_changes_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: temp_current temp_current_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_current
    ADD CONSTRAINT temp_current_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

