
-- некоторые таблицы из этого файла есть в других файлах sql
-- это сокращенный dump из базы данных
--
-- PostgreSQL database dump
--
--
-- Name: add_temp_changes(); Type: FUNCTION; Schema: public; Owner: user
--

--~ Триггерная функция add_temp_changes() делает запись в таблицы
--~ temp_changes и temp_changes_archive
--~ если температура системы или АКБ изменилась
CREATE FUNCTION public.add_temp_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if  (NEW.temp_sys <> OLD.temp_sys) or
      (NEW.temp_akb <> OLD.temp_akb) then
    INSERT INTO temp_changes(
          location,     time,     temp_sys,     temp_akb
    ) VALUES (
      NEW.location, NEW.time, NEW.temp_sys, NEW.temp_akb
    );
    INSERT INTO temp_changes_archive(
          location,     time,     temp_sys,     temp_akb
    ) VALUES (
      NEW.location, NEW.time, NEW.temp_sys, NEW.temp_akb
    );
  end if;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_temp_changes() OWNER TO "user";

--
-- Name: add_temp_static(); Type: FUNCTION; Schema: public; Owner: user
--


--~ функция для заполнения статических данных в таблице temp_static
--~ для анализа (ежедневные отчёты)
CREATE FUNCTION public.add_temp_static() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO
    temp_static ( location, time, temp_sys, temp_akb )
    SELECT        location, time, temp_sys, temp_akb
    FROM temp_current;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_temp_static() OWNER TO "user";

--
-- Name: remove_old_inserts(); Type: FUNCTION; Schema: public; Owner: user
--

--~ удаляет записи давностью больше месяца 
CREATE FUNCTION public.remove_old_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM temp_changes WHERE (now() - time) > '31 days';
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.remove_old_inserts() OWNER TO "user";

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
-- Name: temp_changes; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_changes (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temp_sys integer NOT NULL,
    temp_akb integer NOT NULL
);


ALTER TABLE public.temp_changes OWNER TO "user";

--
-- Name: temp_changes_archive; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_changes_archive (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temp_sys integer NOT NULL,
    temp_akb integer NOT NULL
);


ALTER TABLE public.temp_changes_archive OWNER TO "user";

--
-- Name: temp_current; Type: TABLE; Schema: public; Owner: user
--

CREATE UNLOGGED TABLE public.temp_current (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temp_sys integer NOT NULL,
    temp_akb integer NOT NULL,
    alarm_mains integer,
    out_volt integer,
    out_ampr integer,
    out_watt integer,
    battery1v integer,
    battery2v integer,
    old_time timestamp without time zone,
    old_temp_akb integer,
    old_temp_sys integer
)
WITH (autovacuum_vacuum_scale_factor='0.01');


ALTER TABLE public.temp_current OWNER TO "user";

--
-- Name: temp_static; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_static (
    location text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    temp_sys integer NOT NULL,
    temp_akb integer NOT NULL
);


ALTER TABLE public.temp_static OWNER TO "user";

--
-- Name: locations locations_location_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_location_key UNIQUE (location);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (ip);

ALTER TABLE public.locations CLUSTER ON locations_pkey;


--
-- Name: temp_current temp_current_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_current
    ADD CONSTRAINT temp_current_pkey PRIMARY KEY (location);


--
-- Name: temp_current trig_if_changes; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_changes AFTER UPDATE ON public.temp_current FOR EACH ROW WHEN (((old.temp_akb IS DISTINCT FROM new.temp_akb) OR (old.temp_sys IS DISTINCT FROM new.temp_sys))) EXECUTE PROCEDURE public.add_temp_changes();


--
-- Name: temp_changes trig_if_insert; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER trig_if_insert AFTER INSERT ON public.temp_changes FOR EACH STATEMENT EXECUTE PROCEDURE public.remove_old_inserts();


--
-- Name: temp_changes temp_changes3_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_changes
    ADD CONSTRAINT temp_changes3_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: temp_changes_archive temp_changes_archive_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_changes_archive
    ADD CONSTRAINT temp_changes_archive_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE;


--
-- Name: temp_current temp_current_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_current
    ADD CONSTRAINT temp_current_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: temp_static temp_static_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_static
    ADD CONSTRAINT temp_static_location_fkey FOREIGN KEY (location) REFERENCES public.locations(location) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

