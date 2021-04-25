--
-- PostgreSQL database dump
--

CREATE FUNCTION public.add_average_in_operating_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- после вставки значений в таблицу "архив наработки"
  -- подсчитывает и вставляет последнее среднее значение наработки
  UPDATE operating_time_archive
    SET average = (SELECT (average * 100)::smallint FROM operating_time)
      WHERE time = (
        SELECT time FROM operating_time_archive
          ORDER BY time DESC LIMIT 1
      );
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_average_in_operating_time() OWNER TO "user";

--
-- Name: add_new_changes(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.add_new_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if (NEW.c_life <> OLD.c_life) OR   -- если значения изменились
     (NEW.c__low <> OLD.c__low) OR
     (NEW.c_humi <> OLD.c_humi) OR
     (NEW.a_summ <> OLD.a_summ) OR
     (NEW.a_exrt <> OLD.a_exrt) OR
     (NEW.a_high <> OLD.a_high) OR
     (NEW.a__low <> OLD.a__low) OR
     (NEW.a_humi <> OLD.a_humi) OR
     (NEW.a_faul <> OLD.a_faul) then

    INSERT INTO                      -- то делает первую копию значений
      dehydrator_changes(            -- в таблицу dehydrator_changes
                  ip,
                  time,
                  c_life,
                  c_temp,
                  c_high,
                  c__low,
                  c_humi,
                  a_summ,
                  a_exrt,
                  a_high,
                  a__low,
                  a_humi,
                  a_faul
      ) VALUES(
              NEW.ip,
              NEW.time,
              NEW.c_life,
              NEW.c_temp,
              NEW.c_high,
              NEW.c__low,
              NEW.c_humi,
              NEW.a_summ,
              NEW.a_exrt,
              NEW.a_high,
              NEW.a__low,
              NEW.a_humi,
              NEW.a_faul
      );

    INSERT INTO                      -- вторую копию значений
      dehydrator_changes_archive(    -- в таблицу dehydrator_changes_archive
                  ip,
                  time,
                  c_life,
                  c_temp,
                  c_high,
                  c__low,
                  c_humi,
                  a_summ,
                  a_exrt,
                  a_high,
                  a__low,
                  a_humi,
                  a_faul
      ) VALUES(
              NEW.ip,
              NEW.time,
              NEW.c_life,
              NEW.c_temp,
              NEW.c_high,
              NEW.c__low,
              NEW.c_humi,
              NEW.a_summ,
              NEW.a_exrt,
              NEW.a_high,
              NEW.a__low,
              NEW.a_humi,
              NEW.a_faul
      );

  end if;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_new_changes() OWNER TO "user";

--
-- Name: add_new_operating_time(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.add_new_operating_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if (NEW.c_life <> OLD.c_life) then -- если значения наработки изменились

    INSERT INTO                      -- то делает копию значений
      operating_time_archive(        -- в таблицу "архив наработки"
                  c_life,
                  ip,
                  time
      ) VALUES(
              NEW.c_life,
              NEW.ip,
              NEW.time
      );
  end if;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_new_operating_time() OWNER TO "user";

--
-- Name: remove_old_inserts(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- удаляет из таблицы строки старше 31 дня
  DELETE FROM dehydrator_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.remove_old_inserts() OWNER TO "user";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: dehydrator_changes; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.dehydrator_changes (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false
);


ALTER TABLE public.dehydrator_changes OWNER TO "user";

--
-- Name: dehydrator_changes_archive; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.dehydrator_changes_archive (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false
)
WITH (autovacuum_freeze_min_age='0');  -- сразу замораживается


ALTER TABLE public.dehydrator_changes_archive OWNER TO "user";

--
-- Name: dehydrator_current; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.dehydrator_current (
    c_life smallint,
    c_temp smallint,
    c_high smallint,
    c__low smallint,
    c_humi smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL,
    a_summ boolean DEFAULT false,
    a_exrt boolean DEFAULT false,
    a_high boolean DEFAULT false,
    a__low boolean DEFAULT false,
    a_humi boolean DEFAULT false,
    a_faul boolean DEFAULT false,
    CONSTRAINT dehydrator_current_c_life_check  CHECK ((c_life >  0)),
    CONSTRAINT dehydrator_current_c_life_check1 CHECK ((c_high >= 0)),
    CONSTRAINT dehydrator_current_c_life_check2 CHECK ((c__low >= 0)),
    CONSTRAINT dehydrator_current_c_life_check3 CHECK ((c_humi >= 0))
);


ALTER TABLE public.dehydrator_current OWNER TO "user";

--
-- Name: operating_time; Type: VIEW; Schema: public; Owner: user
--

CREATE VIEW public.operating_time AS
 WITH last_c_life AS (
         SELECT dehydrator_changes.c_life,
            dehydrator_changes."time"
           FROM public.dehydrator_changes
          WHERE (dehydrator_changes.c_life = ( SELECT dehydrator_current.c_life
                   FROM public.dehydrator_current))
          ORDER BY dehydrator_changes."time"
         LIMIT 1
        ), last_but_one AS (
         SELECT dehydrator_changes.c_life,
            dehydrator_changes."time"
           FROM public.dehydrator_changes
          WHERE (dehydrator_changes.c_life = (( SELECT dehydrator_current.c_life
                   FROM public.dehydrator_current) - 1))
          ORDER BY dehydrator_changes."time"
         LIMIT 1
        )
 SELECT l1.c_life AS last_c_life,
    l1."time" AS last_time,
    l2.c_life AS last_but_one_c_life,
    l2."time" AS last_but_one_time,
    (((1)::double precision / ((date_part('epoch'::text, (l1."time" - l2."time")) / (3600)::double precision) / (24)::double precision)))::numeric(3,2) AS average
   FROM last_c_life l1,
    last_but_one l2;


ALTER TABLE public.operating_time OWNER TO "user";

--
-- Name: dehydrator_v; Type: VIEW; Schema: public; Owner: user
--

CREATE VIEW public.dehydrator_v AS
 SELECT dehydrator_current.c_life,
    dehydrator_current.c_temp,
    dehydrator_current.c_high,
    (((dehydrator_current.c__low)::numeric(4,1) / (10)::numeric))::numeric(4,1) AS c__low,
    (((dehydrator_current.c_humi)::numeric(4,1) / (10)::numeric))::numeric(4,1) AS c_humi,
    date_trunc('sec'::text, dehydrator_current."time") AS c_time,
    dehydrator_current.a_summ,
    dehydrator_current.a_exrt,
    dehydrator_current.a_high,
    dehydrator_current.a__low,
    dehydrator_current.a_humi,
    dehydrator_current.a_faul,
    dehydrator_current.ip,
    operating_time.average
   FROM public.dehydrator_current,
    public.operating_time;


ALTER TABLE public.dehydrator_v OWNER TO "user";

--
-- Name: locations; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.locations (
    ip inet NOT NULL,
    location text NOT NULL,
    own text NOT NULL
);


ALTER TABLE public.locations OWNER TO "user";

--
-- Name: operating_time_archive; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.operating_time_archive (
    average smallint,
    c_life smallint,
    ip inet NOT NULL,
    "time" timestamp without time zone NOT NULL
);


ALTER TABLE public.operating_time_archive OWNER TO "user";

--
-- Name: dehydrator_current dehydrator_current_ip_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.dehydrator_current
    ADD CONSTRAINT dehydrator_current_ip_key UNIQUE (ip);


--
-- Name: locations loc_ip_idx; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT loc_ip_idx PRIMARY KEY (ip);


--
-- Name: locations locations_location_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_location_key UNIQUE (location);


--
-- Name: dehydrator_changes_time_idx; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX dehydrator_changes_time_idx ON public.dehydrator_changes USING btree ("time");


--
-- Name: dehydrator_current trig_if_c_life_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_c_life_changes AFTER UPDATE ON public.dehydrator_current FOR EACH ROW EXECUTE PROCEDURE public.add_new_operating_time();


--
-- Name: dehydrator_current trig_if_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_changes AFTER UPDATE ON public.dehydrator_current FOR EACH ROW EXECUTE PROCEDURE public.add_new_changes();


--
-- Name: dehydrator_changes trig_if_insert; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_insert AFTER INSERT ON public.dehydrator_changes FOR EACH STATEMENT EXECUTE PROCEDURE public.remove_old_inserts();


--
-- Name: operating_time_archive trig_if_insert_into_operating_time; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_insert_into_operating_time AFTER INSERT ON public.operating_time_archive FOR EACH ROW EXECUTE PROCEDURE public.add_average_in_operating_time();


--
-- Name: dehydrator_changes_archive dehydrator_changes_archive_ip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.dehydrator_changes_archive
    ADD CONSTRAINT dehydrator_changes_archive_ip_fkey FOREIGN KEY (ip) REFERENCES public.locations(ip) ON UPDATE CASCADE;


--
-- Name: dehydrator_changes dehydrator_changes_ip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.dehydrator_changes
    ADD CONSTRAINT dehydrator_changes_ip_fkey FOREIGN KEY (ip) REFERENCES public.locations(ip) ON UPDATE CASCADE;


--
-- Name: dehydrator_current dehydrator_current_ip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.dehydrator_current
    ADD CONSTRAINT dehydrator_current_ip_fkey FOREIGN KEY (ip) REFERENCES public.locations(ip) ON UPDATE CASCADE;


--
-- Name: operating_time_archive operating_time_archive_ip_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.operating_time_archive
    ADD CONSTRAINT operating_time_archive_ip_fkey FOREIGN KEY (ip) REFERENCES public.locations(ip) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--

